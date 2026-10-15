"""Exercise Yaak package selection without network or system changes."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class YaakTests(unittest.TestCase):
    def run_hook(self, distro, arch, fail=False, installed=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / "os-release"
            release.write_text(f"ID={distro}\n")
            script = (REPO / "scripts/gui/yaak_install.sh").read_text()
            script = script.replace("/etc/os-release", str(release)).replace(
                '"$SCRIPT_DIR/../utils/utils_logging.sh"',
                f'"{REPO}/scripts/utils/utils_logging.sh"',
            )
            installer = root / "installer.sh"
            installer.write_text(script)
            commands = {
                "uname": f'[ "$1" = -s ] && echo Linux || echo {arch}',
                "id": "echo 0",
                "curl": (
                    "exit 22" if fail else
                    'echo "$@"; for arg do target="$arg"; done; touch "$target"'
                ),
                "apt-get": 'echo "APT $*"',
                "dnf": 'echo "DNF $*"',
            }
            if installed:
                commands["yaak"] = "exit 0"
            for name, body in commands.items():
                executable = root / name
                executable.write_text("#!/bin/sh\n" + body + "\n")
                executable.chmod(0o755)
            result = subprocess.run(
                ["sh", str(installer)], capture_output=True, text=True,
                env=dict(os.environ, PATH=f"{root}:/usr/bin:/bin", TMPDIR=directory),
            )
            self.assertFalse(list(root.glob("tmp.*")), "temporary download leaked")
            return result

    def test_packages(self):
        for distro, arch, path, manager in [
            ("ubuntu", "x86_64", "deb-x86_64/yaak-cef_2026.9.0_amd64.deb", "APT"),
            ("debian", "aarch64", "deb-arm_64/yaak-cef_2026.9.0_arm64.deb", "APT"),
            ("fedora", "x86_64", "rpm-x86_64/yaak-2026.9.0-1.x86_64.rpm", "DNF"),
            ("rhel", "aarch64", "rpm-arm_64/yaak-2026.9.0-1.aarch64.rpm", "DNF"),
        ]:
            with self.subTest(distro=distro, arch=arch):
                result = self.run_hook(distro, arch)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(path, result.stdout)
                self.assertIn(f"{manager} install -y", result.stdout)

    def test_failed_download_never_installs(self):
        result = self.run_hook("ubuntu", "x86_64", fail=True)
        self.assertEqual(result.returncode, 22)
        self.assertNotIn("APT install", result.stdout)

    def test_skips(self):
        for distro, arch, installed in [
            ("arch", "x86_64", False),
            ("ubuntu", "riscv64", False),
            ("ubuntu", "x86_64", True),
        ]:
            result = self.run_hook(distro, arch, fail=True, installed=installed)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("install -y", result.stdout)
