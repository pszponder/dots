"""Check first-shell initialization without inherited mise tool paths."""

from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class ShellStartupTests(unittest.TestCase):
    def test_bash_initializes_starship_after_mise_adds_tool_path(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / ".local/bin").mkdir(parents=True)
            (home / "tools").mkdir()
            mise = home / ".local/bin/mise"
            mise.write_text('''#!/bin/sh
case "$1" in
  --version) echo test ;;
  activate) printf 'export PATH="%s/tools:$PATH"\\n' "$HOME" ;;
esac
''')
            starship = home / "tools/starship"
            starship.write_text('''#!/bin/sh
case "$1" in
  --version) echo test ;;
  init) echo 'export STARSHIP_INITIALIZED=yes' ;;
esac
''')
            mise.chmod(0o755)
            starship.chmod(0o755)
            env = {
                "HOME": directory,
                "PATH": "/usr/bin:/bin",
                "TERM": "dumb",
                "XDG_CACHE_HOME": directory + "/cache",
                "XDG_STATE_HOME": directory + "/state",
            }
            result = subprocess.run(
                ["bash", "--noprofile", "--rcfile", str(REPO / "dots/.bashrc"),
                 "-i", "-c", 'printf "initialized=%s\\n" "${STARSHIP_INITIALIZED:-no}"'],
                env=env, cwd=directory, text=True, capture_output=True, timeout=10,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("initialized=yes", result.stdout)


if __name__ == "__main__":
    unittest.main()
