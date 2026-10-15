"""Offline checks for the native Zed installer hook."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class ZedTests(unittest.TestCase):
    def test_existing_install_and_download_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = (REPO / "scripts/gui/zed_install.sh").read_text()
            script = script.replace(
                '"$SCRIPT_DIR/../utils/utils_logging.sh"',
                '"' + str(REPO / "scripts/utils/utils_logging.sh") + '"',
            )
            installer = root / "zed_install.sh"
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

            zed = root / "zed"
            zed.write_text("#!/bin/sh\nexit 0\n")
            zed.chmod(0o755)
            result = subprocess.run(
                ["sh", str(installer)], env=env, capture_output=True, text=True
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("already installed", result.stdout)
            self.assertNotIn("download-attempt", result.stderr)
