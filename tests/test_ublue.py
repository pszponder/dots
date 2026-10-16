"""Offline ublue bootstrap and updater behavior with isolated commands."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


class UblueTests(unittest.TestCase):
    def test_flatpak_preparation_and_missing_prerequisite(self):
        source = (REPO / 'scripts/gui/flatpak_install.sh').read_text()
        source = source.replace('"$SCRIPT_DIR/../utils/utils_logging.sh"',
                                json.dumps(str(REPO / 'scripts/utils/utils_logging.sh')))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = root / 'flatpak.sh'
            script.write_text(source)
            calls = root / 'calls'
            # Only expose the commands this script needs, isolating host Flatpak.
            for name, body in {
                'uname': 'echo Linux',
                'dirname': '/usr/bin/dirname "$@"',
                'id': 'echo 0',
                'dnf': 'echo forbidden >> "$CALLS"; exit 99',
            }.items():
                target = root / name
                target.write_text('#!/bin/sh\n' + body + '\n')
                target.chmod(0o755)
            env = dict(os.environ, PATH=str(root), CALLS=str(calls))
            result = subprocess.run(['/bin/sh', str(script), '--ublue'], env=env,
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Flatpak is required', result.stderr)
            self.assertFalse(calls.exists())
            flatpak = root / 'flatpak'
            flatpak.write_text('#!/bin/sh\necho "$*" >> "$CALLS"\n')
            flatpak.chmod(0o755)
            for _ in range(2):
                result = subprocess.run(['/bin/sh', str(script), '--ublue'], env=env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            lines = calls.read_text().splitlines()
            self.assertEqual(lines[:2], lines[2:])
            self.assertIn('remote-add --system --if-not-exists flathub', lines[0])
            self.assertIn('remote-add --user --if-not-exists flathub', lines[1])

    def test_profile_has_only_requested_packages(self):
        base = tomllib.loads((REPO / 'bootstrap/mise.toml').read_text())
        profile = tomllib.loads((REPO / 'bootstrap/mise.workstation-ublue.toml').read_text())
        self.assertFalse(base['bootstrap'].get('packages'))
        expected = {
            'flatpak:com.visualstudio.code', 'flatpak:md.obsidian.Obsidian',
            'flatpak:com.discordapp.Discord', 'flatpak:app.zen_browser.zen',
            'flatpak:dev.zed.Zed', 'flatpak:com.brave.Browser',
            'flatpak-user:io.podman_desktop.PodmanDesktop',
            *(f'brew-cask:font-{name}-nerd-font' for name in
              ('caskaydia-cove', 'caskaydia-mono', 'jetbrains-mono')),
        }
        self.assertEqual(set(profile['bootstrap']['packages']), expected)
        for key, value in profile['bootstrap']['packages'].items():
            if key.startswith('brew-cask:'):
                self.assertEqual(value, {'os': ['linux']})

    def test_atomic_updates_preview_execution_and_failures(self):
        source = (REPO / 'dots/.local/bin/system-update').read_text()
        source = source.rsplit('main "$@"', 1)[0]
        # Avoid needing a deployed configuration while exercising the full workflow.
        source += '\nvalidate_profile() { :; }\nmain "$@"\n'
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = root / 'update'
            script.write_text(source)
            calls = root / 'calls'
            for name in ('bootc', 'rpm-ostree', 'flatpak', 'mise', 'brew', 'sudo'):
                target = root / name
                body = 'echo "' + name + ' $*" >> "$CALLS"\n'
                if name == 'sudo':
                    body = 'exec "$@"\n'
                elif name == 'bootc':
                    body = '''if [ "$1" = status ]; then
  if [ "$BOOTC_MANAGED" = yes ]; then
    echo '{"status":{"booted":{"image":{"image":"example"}}}}'
  else
    echo '{"status":{"booted":null}}'
  fi
  exit 0
fi
''' + body
                body += 'if [ "$FAIL_COMMAND" = "' + name + '" ]; then exit 1; fi\nexit 0\n'
                target.write_text('#!/bin/sh\n' + body)
                target.chmod(0o755)
            env = dict(os.environ, HOME=str(root), PATH=f'{root}:/usr/bin:/bin',
                       DOTFILES_PROFILE='workstation-ublue', DOTFILES_REPO=str(REPO),
                       CALLS=str(calls), BOOTC_MANAGED='yes', FAIL_COMMAND='')
            for managed, command in (('yes', 'bootc'), ('no', 'rpm-ostree')):
                env['BOOTC_MANAGED'] = managed
                preview = subprocess.run(['bash', str(script), '--dry-run'], env=env,
                                         capture_output=True, text=True)
                self.assertEqual(preview.returncode, 0, preview.stderr)
                self.assertIn(command + ' upgrade', preview.stdout)
                self.assertNotIn('dnf ', preview.stdout)
                self.assertFalse(calls.exists())
                run = subprocess.run(['bash', str(script)], env=env, capture_output=True, text=True)
                self.assertEqual(run.returncode, 0, run.stderr)
                recorded = calls.read_text()
                self.assertIn(command + ' upgrade', recorded)
                self.assertIn('flatpak update --user --assumeyes', recorded)
                self.assertIn('flatpak update --system --assumeyes', recorded)
                self.assertIn('bootstrap packages upgrade --yes', recorded)
                calls.unlink()
            env.update(BOOTC_MANAGED='yes', FAIL_COMMAND='bootc')
            failed = subprocess.run(['bash', str(script)], env=env, capture_output=True, text=True)
            self.assertEqual(failed.returncode, 1)
            self.assertIn('Some updates failed', failed.stderr)
            self.assertIn('flatpak update --system', calls.read_text())
            calls.unlink()
            (root / 'bootc').unlink()
            (root / 'rpm-ostree').unlink()
            missing = subprocess.run(['bash', str(script), '--dry-run'], env=env,
                                     capture_output=True, text=True)
            self.assertEqual(missing.returncode, 1)
            self.assertIn('Atomic host requires', missing.stderr)
