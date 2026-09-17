"""Read discovery from the real Claude launcher, without authentication or model calls."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

expected = set(json.loads(sys.argv[1]))
home = Path.home()
config_dir = home / 'relocated-claude'
config_dir.mkdir()
env = dict(os.environ, CLAUDE_CONFIG_DIR=str(config_dir))
for key in ['LITELLM_API_KEY', 'ANTHROPIC_API_KEY', 'CLAUDE_CODE_OAUTH_TOKEN']:
    env.pop(key, None)

settings = config_dir / 'settings.json'
settings.write_text('{"model":"sonnet","env":{"PERSONAL_SETTING":"keep"}}\n')
credentials = config_dir / '.credentials.json'
credentials.write_text('{}\n')
session = config_dir / 'projects' / 'keep.jsonl'
session.parent.mkdir()
session.write_text('session sentinel\n')
preserved = {path: path.read_bytes() for path in [settings, credentials, session]}


def run(*args):
    return subprocess.run(['claude', *args], env=env, text=True,
                          capture_output=True, timeout=60, check=True).stdout


def inventory(plugin):
    # Claude's own inventory, rather than inspecting the translated files.
    details = run('plugin', 'details', plugin)
    match = re.search(r'^\s*Skills \((\d+)\)\s+([^\n]+)', details, re.MULTILINE)
    assert match, details
    names = set(match[2].split(', '))
    assert len(names) == int(match[1]), details
    return names, details


for juspay in [None, '0', '1']:
    if juspay is None:
        env.pop('JUSPAY', None)
    else:
        env['JUSPAY'] = juspay
    assert '(Claude Code)' in run('--version')
    plugins = json.loads(run('plugin', 'list', '--json'))
    assert {p['id'] for p in plugins} == {'juspay-skills@inline', 'kolu@inline'}, plugins
    assert all(p['enabled'] and p['scope'] == 'session' for p in plugins), plugins

assert inventory('juspay-skills')[0] == expected
kolu_skills, kolu_details = inventory('kolu')
assert kolu_skills == {'kolu'}
assert re.search(r'MCP servers \(1\)\s+kolu\b', kolu_details), kolu_details
for plugin in plugins:
    run('plugin', 'validate', plugin['installPath'])

# Kolu is an isolated protocol fixture on PATH in this VM. This confirms Claude
# launches the server from the plugin declaration with the expected arguments.
health = run('mcp', 'list')
assert re.search(r'plugin:kolu:kolu: kolu mcp.*Connected', health), health

# A user's extra plugin composes with the bundled roots, including a spaced path.
personal = home / 'personal plugin'
(personal / '.claude-plugin').mkdir(parents=True)
(personal / '.claude-plugin/plugin.json').write_text('{"name":"personal"}')
(personal / 'skills' / 'personal').mkdir(parents=True)
(personal / 'skills/personal/SKILL.md').write_text('---\nname: personal\ndescription: Personal skill\n---\n')
extra = json.loads(run('--plugin-dir', str(personal), 'plugin', 'list', '--json'))
assert {p['id'] for p in extra} == {'juspay-skills@inline', 'kolu@inline', 'personal@inline'}, extra

for path, contents in preserved.items():
    assert path.read_bytes() == contents, path
assert not (config_dir / 'plugins/installed_plugins.json').exists()
assert not (config_dir / 'plugins/known_marketplaces.json').exists()
print('Claude loads every bundled skill and Kolu MCP; user state and extra plugins are preserved')
