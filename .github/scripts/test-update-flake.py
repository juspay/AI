"""Check distribution update reporting offline, without opening a PR."""
import os
import json
import shlex
from itertools import product
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent


class UpdateFlakeTests(unittest.TestCase):
    def test_omp_version_follows_framework_lock_edges(self):
        # Node names can acquire suffixes when input graphs are combined.
        workflow = (SCRIPTS.parent / 'workflows/update-flake.yml').read_text()
        commands = [line.strip()[len('version=$('):-1]
                    for line in workflow.splitlines() if 'version=$(jq ' in line]
        self.assertEqual(len(commands), 2)
        lock = {"nodes": {
            "root": {"inputs": {"agent-distro": "framework_2"}},
            "framework_2": {"inputs": {"oh-my-pi": "omp_2"}},
            "omp_2": {"original": {"ref": "v18.2.4"}},
            "oh-my-pi": {"original": {"ref": "wrong-node"}},
        }}
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / 'flake.lock').write_text(json.dumps(lock))
            for command in commands:
                result = subprocess.run(shlex.split(command), cwd=directory,
                                        check=True, capture_output=True, text=True)
                self.assertEqual(result.stdout.strip(), 'v18.2.4')

    def test_report_uses_resolved_versions_and_preserves_lock_log(self):
        for omp_changed, codex_changed, claude_changed in product([False, True], repeat=3):
            with self.subTest(omp=omp_changed, codex=codex_changed, claude=claude_changed), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / 'flake-update.log').write_text('framework and skills revisions changed\ntest lock updated\n')
                env = dict(os.environ, OMP_BEFORE='v18.2.4',
                           OMP_AFTER='v18.2.5' if omp_changed else 'v18.2.4',
                           CODEX_BEFORE='0.153.0', CODEX_AFTER='0.154.0' if codex_changed else '0.153.0',
                           CLAUDE_BEFORE='2.1.273', CLAUDE_AFTER='2.1.274' if claude_changed else '2.1.273',
                           GITHUB_SERVER_URL='https://github.com', GITHUB_REPOSITORY='juspay/AI',
                           GITHUB_RUN_ID='123', RUNNER_TEMP=str(root), GITHUB_OUTPUT=str(root / 'outputs'))
                subprocess.run(['python3', str(SCRIPTS / 'describe-flake-update.py')], env=env, check=True)
                outputs = dict(line.split('=', 1) for line in (root / 'outputs').read_text().splitlines())
                body = Path(outputs['pr-body-path']).read_text()
                self.assertIn('framework and skills revisions changed\ntest lock updated', body)
                self.assertIn('https://github.com/juspay/AI/actions/runs/123', body)
                self.assertEqual('oh-my-pi v18.2.4 → v18.2.5' in outputs['pr-title'], omp_changed)
                self.assertEqual('Codex 0.153.0 → 0.154.0' in outputs['pr-title'], codex_changed)
                self.assertEqual('Claude Code 2.1.273 → 2.1.274' in outputs['pr-title'], claude_changed)
                if claude_changed:
                    self.assertIn('/releases/tag/v2.1.274', body)
                else:
                    self.assertIn('Claude Code unchanged (`2.1.273`)', body)
                if codex_changed:
                    self.assertIn('/releases/tag/rust-v0.154.0', body)
                else:
                    self.assertIn('Codex unchanged (`0.153.0`)', body)
                if omp_changed:
                    self.assertIn('/releases/tag/v18.2.5', body)
                else:
                    self.assertIn('oh-my-pi unchanged (`v18.2.4`)', body)
                self.assertIn('OMP release selection happens there', body)


if __name__ == '__main__':
    unittest.main()
