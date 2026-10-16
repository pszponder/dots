"""Offline checks for workstation browser setup."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
LOGGING = REPO / "scripts/utils/utils_logging.sh"


class BrowserTests(unittest.TestCase):
    def test_helium_installs_with_existing_repository_and_skips_existing_app(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            keyring = root / 'helium.gpg'
            sources = root / 'helium.list'
            keyring.touch()
            sources.touch()
            release = root / 'os-release'
            release.write_text('ID=debian\n')
            source = (REPO / 'scripts/gui/helium_repo.sh').read_text()
            source = source.replace('"$SCRIPT_DIR/../utils/utils_logging.sh"', f'"{LOGGING}"')
            source = source.replace('/etc/os-release', str(release))
            source = source.replace('/usr/share/keyrings/helium.gpg', str(keyring))
            source = source.replace('/etc/apt/sources.list.d/helium.list', str(sources))
            source = source.replace('command -v helium ', 'command -v test-helium ')
            script = root / 'installer.sh'
            script.write_text(source)
            for name, body in {
                'uname': 'echo Linux',
                'id': 'echo 0',
                'apt-get': 'echo "$*" >> "$CALLS"',
            }.items():
                target = root / name
                target.write_text('#!/bin/sh\n' + body + '\n')
                target.chmod(0o755)
            calls = root / 'calls'
            env = dict(os.environ, PATH=f'{root}:/usr/bin:/bin', CALLS=str(calls))
            result = subprocess.run(['sh', str(script)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(calls.read_text().strip(), 'install -y helium-bin')
            calls.unlink()
            app = root / 'test-helium'
            app.write_text('#!/bin/sh\nexit 0\n')
            app.chmod(0o755)
            result = subprocess.run(['sh', str(script)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(calls.exists())

    def test_brave_origin_existing_install_and_download_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = (REPO / "scripts/gui/brave_origin_install.sh").read_text()
            script = script.replace("brave-origin", "test-brave-origin")
            script = script.replace(
                '"$SCRIPT_DIR/../utils/utils_logging.sh"', f'"{LOGGING}"'
            )
            installer = root / "install.sh"
            installer.write_text(script)
            for name, body in {
                "uname": "echo Linux",
                "curl": "echo download-attempt >&2; exit 22",
            }.items():
                target = root / name
                target.write_text("#!/bin/sh\n" + body + "\n")
                target.chmod(0o755)
            env = dict(os.environ, PATH=str(root) + ":/usr/bin:/bin")

            result = subprocess.run(
                ["sh", str(installer)], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 22, result.stdout + result.stderr)
            self.assertIn("download-attempt", result.stderr)

            brave = root / "test-brave-origin"
            brave.write_text("#!/bin/sh\nexit 0\n")
            brave.chmod(0o755)
            result = subprocess.run(
                ["sh", str(installer)], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("already installed", result.stdout)
            self.assertNotIn("download-attempt", result.stderr)

    def test_helium_repository_is_debian_only(self):
        source = (REPO / "scripts/gui/helium_repo.sh").read_text()
        source = source.replace(
            '"$SCRIPT_DIR/../utils/utils_logging.sh"', f'"{LOGGING}"'
        )
        source = source.rsplit('main "$@"', 1)[0]
        harness = source + "\nuname() { echo Linux; }\nmain\n"
        with tempfile.TemporaryDirectory() as directory:
            release = Path(directory) / "os-release"
            script = harness.replace("/etc/os-release", str(release))
            for distro in ("fedora", "arch"):
                with self.subTest(distro=distro):
                    release.write_text(f"ID={distro}\n")
                    result = subprocess.run(
                        ["sh", "-c", script], capture_output=True, text=True
                    )
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
