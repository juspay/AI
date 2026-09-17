"""Check release policy and reporting offline, without opening a PR."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent


class UpdateFlakeTests(unittest.TestCase):
    def test_omp_pin_moves_only_forward(self):
        cases = [
            ('v18.2.4', 'v18.2.5', 'v18.2.5'),
            ('v18.2.9', 'v18.2.10', 'v18.2.10'),
            ('v18.2.4', 'v18.2.4', 'v18.2.4'),
            ('v18.2.4', 'v18.2.3', 'v18.2.4'),
            ('v18.2.4', 'invalid', None),
            ('v18.2.4', '', None),
            ('missing', 'v18.2.5', None),
        ]
        for before, latest, after in cases:
            with self.subTest(before=before, latest=latest), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                flake = root / 'flake.nix'
                original = f'oh-my-pi.url = "github:can1357/oh-my-pi/{before}";\n'
                flake.write_text(original)
                gh = root / 'gh'
                gh.write_text('#!/bin/sh\nprintf "%s\\n" "$TEST_LATEST"\n')
                gh.chmod(0o755)
                output = root / 'outputs'
                env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                           TEST_LATEST=latest, GITHUB_OUTPUT=str(output))
                result = subprocess.run(['bash', str(SCRIPTS / 'advance-omp-pin.sh')],
                                        cwd=root, env=env, capture_output=True, text=True)
                if after is None:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(flake.read_text(), original)
                    self.assertFalse(output.exists())
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(flake.read_text(), original.replace(before, after))
                    self.assertEqual(output.read_text(), f'before={before}\nafter={after}\nlatest={latest}\n')

    def test_report_uses_resolved_versions_and_preserves_lock_log(self):
        for omp_changed in [False, True]:
            for codex_changed in [False, True]:
                with self.subTest(omp=omp_changed, codex=codex_changed), tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    (root / 'flake-update.log').write_text('skills revision changed\n')
                    env = dict(os.environ, OMP_BEFORE='v18.2.4',
                               OMP_AFTER='v18.2.5' if omp_changed else 'v18.2.4',
                               OMP_LATEST='v18.2.5' if omp_changed else 'v18.2.3',
                               CODEX_BEFORE='0.153.0', CODEX_AFTER='0.154.0' if codex_changed else '0.153.0',
                               GITHUB_SERVER_URL='https://github.com', GITHUB_REPOSITORY='juspay/AI',
                               GITHUB_RUN_ID='123', RUNNER_TEMP=str(root), GITHUB_OUTPUT=str(root / 'outputs'))
                    subprocess.run(['python3', str(SCRIPTS / 'describe-flake-update.py')], env=env, check=True)
                    outputs = dict(line.split('=', 1) for line in (root / 'outputs').read_text().splitlines())
                    body = Path(outputs['pr-body-path']).read_text()
                    self.assertIn('skills revision changed', body)
                    self.assertIn('https://github.com/juspay/AI/actions/runs/123', body)
                    self.assertEqual('oh-my-pi v18.2.4 → v18.2.5' in outputs['pr-title'], omp_changed)
                    self.assertEqual('Codex 0.153.0 → 0.154.0' in outputs['pr-title'], codex_changed)
                    if codex_changed:
                        self.assertIn('/releases/tag/rust-v0.154.0', body)
                    else:
                        self.assertIn('Codex unchanged (`0.153.0`)', body)
                    if not omp_changed:
                        self.assertIn('the pin only moves forward', body)


if __name__ == '__main__':
    unittest.main()
