import json
import os
import subprocess
import tempfile
import time

# ACP discovers skills without authentication or model calls. Keep stdin open
# while inspecting the running harness's environment, not its wrapper source.
with tempfile.TemporaryDirectory() as cwd, tempfile.TemporaryFile(mode='w+') as output:
    process = subprocess.Popen(['omp', 'acp'], cwd=cwd, stdin=subprocess.PIPE,
                               stdout=output, stderr=subprocess.PIPE, text=True)
    try:
        process.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize',
            'params': {'protocolVersion': 1, 'clientCapabilities': {'fs': {'readTextFile': False, 'writeTextFile': False}}}}) + '\n')
        process.stdin.flush()
        time.sleep(3)
        assert process.poll() is None
        environ = open(f'/proc/{process.pid}/environ', 'rb').read().split(b'\0')
        assert not any(v.startswith((b'LITELLM_BASE_URL=', b'OMP_SKIP_SETUP=')) for v in environ), environ
        process.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': 2, 'method': 'session/new',
            'params': {'cwd': cwd, 'mcpServers': []}}) + '\n')
        process.stdin.flush()
        time.sleep(10)
        output.seek(0)
        messages = [json.loads(line) for line in output if line.strip()]
        assert any(m.get('id') == 2 and 'result' in m for m in messages), messages
        assert 'skill:' not in json.dumps(messages), messages
    finally:
        process.terminate()
        process.communicate(timeout=10)
