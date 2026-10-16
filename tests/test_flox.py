"""Offline checks for Flox integration; never invoke the real installer."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class FloxTests(unittest.TestCase):
    def test_installer_platform_gates_and_download_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / 'os-release'
            release.write_text('ID=ubuntu\nID_LIKE=debian\n')
            script = (REPO / 'scripts/cli/flox_install.sh').read_text()
            script = script.replace('/etc/os-release', str(release))
            script = script.replace('"$SCRIPT_DIR/../utils/utils_logging.sh"',
                                    '"' + str(REPO / 'scripts/utils/utils_logging.sh') + '"')
            # Isolate host Nix/ostree state from these simulated machines.
            for path in ('/nix/store', '/run/ostree-booted', '/ostree'):
                script = script.replace(path, str(root / path.lstrip('/')))
            # Ignore host binaries while still detecting the fixture's Flox.
            for name in ('flox', 'nix'):
                script = script.replace('command -v ' + name,
                                        'test -x "' + str(root / name) + '"')
            installer = root / 'install.sh'
            installer.write_text(script)
            for name, body in {
                'uname': 'case "$1" in -s) echo Linux;; -m) echo x86_64;; esac',
                'curl': 'echo download-attempt >&2; exit 22',
                'apt-get': 'exit 0',
            }.items():
                target = root / name
                target.write_text('#!/bin/sh\n' + body + '\n')
                target.chmod(0o755)
            env = dict(os.environ, PATH=str(root) + ':/usr/bin:/bin')
            result = subprocess.run(['sh', str(installer)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 22, result.stdout + result.stderr)
            self.assertIn('download-attempt', result.stderr)
            release.write_text('ID=omarchy\nID_LIKE=arch\n')
            result = subprocess.run(['sh', str(installer)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0)
            self.assertIn('Skipping Flox', result.stdout)
            self.assertNotIn('download-attempt', result.stderr)
            flox = root / 'flox'
            flox.write_text('#!/bin/sh\nexit 0\n')
            flox.chmod(0o755)
            result = subprocess.run(['sh', str(installer)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0)
            self.assertIn('already installed', result.stdout)

    def test_updater_targets_default_and_preserves_preview_and_failures(self):
        source = (REPO / 'dots/.local/bin/system-update').read_text()
        source = source.rsplit('main "$@"', 1)[0]
        harness = source + '''
preview=false
failures=()
flox() { printf 'called: %s\\n' "$*"; return 7; }
update_flox
test "${#failures[@]}" = 1 || exit 1
preview=true
update_flox
unset -f flox
has() { return 1; }
update_flox
'''
        result = subprocess.run(['bash', '-c', harness], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.count('called: upgrade --default'), 1)
        self.assertIn('Flox is not installed; skipping.', result.stdout)
