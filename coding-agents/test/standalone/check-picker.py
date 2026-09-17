import os
import pty
import select
import time

def choose(selection, expected):
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe('ai', ['ai', '--version'], dict(os.environ, JUSPAY='0'))
    output = b''
    sent = False
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
        if not sent and b'Agent [1/2/3]' in output:
            os.write(fd, selection)
            sent = True
    else:
        os.kill(pid, 9)
        raise AssertionError(output)
    _, status = os.waitpid(pid, 0)
    os.close(fd)
    assert os.waitstatus_to_exitcode(status) == 0, output
    assert expected in output, output

choose(b'2\n', b'codex-cli')
choose(b'3\n', b'(Claude Code)')
choose(b'wrong\n1\n', b'Enter 1 for Oh My Pi')
choose(b'q\n', b'Choose a coding agent')
