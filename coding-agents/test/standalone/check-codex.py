"""Exercise the installed launcher and Codex's own discovery protocols offline."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tomllib

expected = set(json.loads(sys.argv[1]))
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
    return subprocess.run(['codex', *args], env=env, text=True,
                          capture_output=True, timeout=60, **kwargs)


for gateway in [None, '0', '1']:
    if gateway is None:
        env.pop('AI_GATEWAY', None)
    else:
        env['AI_GATEWAY'] = gateway
    result = run('--version', check=True)
    assert 'codex-cli' in result.stdout, result
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
    process = subprocess.Popen(['codex', 'app-server'], env=env,
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

# Reinstall must repair cached contents even without a manifest version bump.
# Use Codex's reported path instead of assuming its private cache layout.
cached_skill = Path(skills['juspay-skills:nix-haskell']['path'])
cached_skill.chmod(0o644)  # Native installation preserves the store file's read-only mode.
cached_skill.write_text(
    '---\nname: stale\ndescription: stale cached skill\n---\n')
assert 'juspay-skills:nix-haskell' in loaded_skills()
assert run('not-a-subcommand').returncode != 0

invalid = 'model = [\n'
config.write_text(invalid)
assert run('--version').returncode != 0
assert config.read_text() == invalid
print('Codex loads every bundled skill and Kolu MCP; user state survives; no Juspay credentials required')
