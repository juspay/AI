"""Exercise the installed launcher and Codex's own discovery protocols offline."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tomllib

expected = set(json.loads(sys.argv[1]))
launcher = 'codex'
home = Path.home()
codex_home = home / 'relocated-codex'
codex_home.mkdir()
env = dict(os.environ, CODEX_HOME=str(codex_home))
env.pop('LITELLM_API_KEY', None)
config = codex_home / 'config.toml'
original = '''# personal settings
model = "my-model"
[ mcp_servers.personal ]
command = "true"
[plugins."kolu@juspay-ai".mcp_servers.kolu]
enabled_tools = ["my-tool"]
'''
config.write_text(original)
auth = codex_home / 'auth.json'
auth.write_text('{"OPENAI_API_KEY":"test-api-key"}\n')
session = codex_home / 'sessions' / 'keep.jsonl'
session.parent.mkdir()
session.write_text('session sentinel\n')
skill = codex_home / 'skills' / 'personal' / 'SKILL.md'
skill.parent.mkdir(parents=True)
skill.write_text('---\nname: personal\ndescription: Personal skill\n---\n')


def run(*args, **kwargs):
    return subprocess.run([launcher, *args], env=env, text=True,
                          capture_output=True, timeout=60, **kwargs)


def upstream(*args):
    return subprocess.run(['codex-upstream', *args], env=env, text=True,
                          capture_output=True, timeout=60, check=True)


def marketplace_root():
    marketplaces = json.loads(upstream('plugin', 'marketplace', 'list', '--json').stdout)
    return next(m['root'] for m in marketplaces['marketplaces'] if m['name'] == 'juspay-ai')


def installed_plugins():
    installed = json.loads(upstream('plugin', 'list', '--json').stdout)['installed']
    return {p['pluginId']: p for p in installed}


assert 'codex-cli' in run('--version', check=True).stdout
first_marketplace = marketplace_root()
assert first_marketplace.startswith('/nix/store/'), first_marketplace
for plugin_id in ['juspay-skills@juspay-ai', 'kolu@juspay-ai']:
    plugin = installed_plugins()[plugin_id]
    assert plugin['installed'] and plugin['enabled'], plugin

# Check the store-path regression before steady-state preferences, so reverting
# the adapter fails at the second build with Codex's different-source error.
launcher = 'codex-updated'
relaunch = run('--version')
assert relaunch.returncode == 0, relaunch.stderr
assert 'codex-cli' in relaunch.stdout
assert marketplace_root() != first_marketplace
launcher = 'codex'
run('--version', check=True)
assert marketplace_root() == first_marketplace

# Codex 0.154.0 has no `plugin disable` command; use its persistent setting.
enabled_setting = '[plugins."juspay-skills@juspay-ai"]\nenabled = true'
disabled_setting = '[plugins."juspay-skills@juspay-ai"]\nenabled = false'
assert enabled_setting in config.read_text()
config.write_text(config.read_text().replace(enabled_setting, disabled_setting))
disabled_config = config.read_bytes()
assert not installed_plugins()['juspay-skills@juspay-ai']['enabled']
assert 'codex-cli' in run('--version', check=True).stdout
assert marketplace_root() == first_marketplace
assert not installed_plugins()['juspay-skills@juspay-ai']['enabled']
assert config.read_bytes() == disabled_config

# A second build must replace the old registration and re-enable its plugins.
launcher = 'codex-updated'
relaunch = run('--version')
assert relaunch.returncode == 0, relaunch.stderr
assert 'codex-cli' in relaunch.stdout
store_marketplace = marketplace_root()
assert store_marketplace.startswith('/nix/store/'), store_marketplace
assert store_marketplace != first_marketplace
plugins = installed_plugins()
for plugin_id in ['juspay-skills@juspay-ai', 'kolu@juspay-ai']:
    assert plugins[plugin_id]['installed'] and plugins[plugin_id]['enabled'], plugins


for gateway in [None, '0', '1']:
    if gateway is None:
        env.pop('AI_GATEWAY', None)
    else:
        env['AI_GATEWAY'] = gateway
    result = run('--version', check=True)
    assert 'codex-cli' in result.stdout, result
    assert marketplace_root() == store_marketplace
    settings = tomllib.loads(config.read_text())
    assert settings['model'] == 'my-model'
    assert 'model_provider' not in settings
    assert '# personal settings' in config.read_text()
    assert settings['plugins']['kolu@juspay-ai']['mcp_servers']['kolu']['enabled_tools'] == ['my-tool']
    assert auth.read_text() == '{"OPENAI_API_KEY":"test-api-key"}\n'
    assert session.read_text() == 'session sentinel\n'

servers = {s['name']: s for s in json.loads(run('mcp', 'list', '--json', check=True).stdout)}
assert {'personal', 'kolu'} <= servers.keys(), servers
assert servers['kolu']['enabled']
assert servers['kolu']['transport']['command'] == 'kolu'
assert servers['kolu']['transport']['args'] == ['mcp']
assert 'litellm' not in config.read_text().lower()


def loaded_skills():
    # No thread or model request: initialize, then ask the real app server for
    # its effective skills. A timeout also catches protocol changes in updates.
    process = subprocess.Popen([launcher, 'app-server'], env=env,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.DEVNULL, text=True)
    def request(request_id, method, params):
        process.stdin.write(json.dumps({'id': request_id, 'method': method, 'params': params}) + '\n')
        process.stdin.flush()
        for line in process.stdout:
            response = json.loads(line)
            if response.get('id') == request_id:
                assert 'error' not in response, response
                return response['result']
        raise AssertionError('Codex exited without answering ' + method)

    def timeout(*_):
        raise TimeoutError('Codex skill discovery timed out')

    signal.signal(signal.SIGALRM, timeout)
    signal.alarm(60)
    try:
        request(1, 'initialize', {'clientInfo': {'name': 'ai-test', 'version': '1'},
                                  'capabilities': {'experimentalApi': True}})
        process.stdin.write('{"method":"initialized"}\n')
        process.stdin.flush()
        result = request(2, 'skills/list', {'cwds': [str(home)], 'forceReload': True})
        entry = result['data'][0]
        assert not entry['errors'], entry['errors']
        return {skill['name']: skill for skill in entry['skills'] if skill['enabled']}
    finally:
        signal.alarm(0)
        process.terminate()
        process.wait(timeout=10)


skills = loaded_skills()
expected_names = {'juspay-skills:' + name for name in expected} | {'kolu:kolu'}
bundled = {name for name in skills if name.startswith(('juspay-skills:', 'kolu:'))}
assert bundled == expected_names, (bundled, expected_names)
assert 'personal' in skills

# Removing a plugin also stays in effect until a different build is launched.
# Run this after the preservation checks: Codex's explicit remove command
# deletes that plugin's own configuration, including its MCP preferences.
launcher = 'codex'
run('--version', check=True)
assert marketplace_root() == first_marketplace
skills = loaded_skills()

# A steady-state launch must leave cached contents alone.
# Use Codex's reported path instead of assuming its private cache layout.
cached_skill = Path(skills['juspay-skills:nix-haskell']['path'])
cached_skill.chmod(0o644)  # Native installation preserves the store file's read-only mode.
cached_contents = '---\nname: stale\ndescription: stale cached skill\n---\n'
cached_skill.write_text(cached_contents)
run('--version', check=True)
assert cached_skill.read_text() == cached_contents

upstream('plugin', 'remove', 'kolu@juspay-ai')
assert 'kolu@juspay-ai' not in installed_plugins()
removed_config = config.read_bytes()
run('--version', check=True)
assert marketplace_root() == first_marketplace
assert 'kolu@juspay-ai' not in installed_plugins()
assert config.read_bytes() == removed_config
launcher = 'codex-updated'
run('--version', check=True)
assert marketplace_root() == store_marketplace
# The changed path must replace the edited cache with the real bundled skill.
reinstalled_skills = loaded_skills()
reinstalled_skill = Path(reinstalled_skills['juspay-skills:nix-haskell']['path'])
assert reinstalled_skill.read_text() != cached_contents
assert reinstalled_skill.read_text() == (Path(store_marketplace) / 'juspay-skills/skills/nix-haskell/SKILL.md').read_text()
kolu = installed_plugins()['kolu@juspay-ai']
assert kolu['installed'] and kolu['enabled'], kolu
settings = tomllib.loads(config.read_text())
assert settings['model'] == 'my-model'
assert '# personal settings' in config.read_text()
assert auth.read_text() == '{"OPENAI_API_KEY":"test-api-key"}\n'
assert session.read_text() == 'session sentinel\n'
assert run('not-a-subcommand').returncode != 0

invalid = 'model = [\n'
config.write_text(invalid)
assert run('--version').returncode != 0
assert config.read_text() == invalid
print('Codex loads every bundled skill and Kolu MCP; user state survives; no Juspay credentials required')
