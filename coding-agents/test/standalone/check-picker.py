import os
import pty
import select
import time


def choose(profile, harness, expected, overrides=None, command='ai', status=0):
    pid, fd = pty.fork()
    if pid == 0:
        env = dict(os.environ, AI_GATEWAY='0')
        env.pop('AI_PROFILE', None)
        env.pop('AI_HARNESS', None)
        env.update(overrides or {})
        os.execvpe(command, [command, '--version'], env)
    output = b''
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        if not select.select([fd], [], [], 1)[0]:
            continue
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        if not chunk:
            break
        output += chunk
        if profile is not None and b'Profile (name or number' in output:
            os.write(fd, profile)
            profile = None
        if harness is not None and b'Agent [1/2/3]' in output:
            os.write(fd, harness)
            harness = None
    else:
        os.kill(pid, 9)
        raise AssertionError(output)
    _, result = os.waitpid(pid, 0)
    os.close(fd)
    assert os.waitstatus_to_exitcode(result) == status, output
    assert expected in output, output


choose(b'juspay\n', b'2\n', b'codex-cli')
choose(b'1\n', b'3\n', b'(Claude Code)')
choose(b'wrong\nvanilla\n', b'wrong\n1\n', b'Enter 1 for Oh My Pi')
choose(b'kolu\n', b'q\n', b'Kolu skill and MCP server')
choose(b'q\n', None, b'Choose a profile')
choose(None, b'q\n', b'uses its own login', command='ai-juspay')
choose(None, b'3\n', b'(Claude Code)', {'AI_PROFILE': 'vanilla'})
choose(b'vanilla\n', None, b'codex-cli', {'AI_HARNESS': 'codex'})
choose(None, None, b'codex-cli', {'AI_PROFILE': 'vanilla', 'AI_HARNESS': 'codex'})
choose(None, None, b'valid values: juspay, kolu, vanilla', {'AI_PROFILE': 'bad'}, status=1)
choose(None, None, b'valid values: omp, codex, claude', {'AI_PROFILE': 'vanilla', 'AI_HARNESS': 'bad'}, status=1)

# Ctrl-D on an empty canonical input line must terminate either picker.
choose(b'\x04', None, b'Choose a profile', status=1)
choose(None, b'\x04', b'Choose a coding agent', command='ai-juspay', status=1)
