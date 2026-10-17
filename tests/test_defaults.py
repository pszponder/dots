"""Apply defaults against an isolated desktop and application registry."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/bootstrap/configure_defaults.sh"


class DefaultsTests(unittest.TestCase):
    def test_apply_repeat_and_missing_application(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "bin"
            binary.mkdir()
            log = root / "calls"
            for name in ("xdg-settings", "xdg-mime", "xdg-terminal-exec", "gsettings", "id"):
                path = binary / name
                path.write_text("#!/bin/sh\n" + ("echo 1000\n" if name == "id" else
                                'printf "%s %s\\n" "' + name + '" "$*" >> "$LOG"\n'))
                path.chmod(0o755)
            applications = root / "data/applications"
            applications.mkdir(parents=True)
            for app in ("ghostty_ghostty.desktop", "zen.desktop"):
                (applications / app).touch()
            config = root / "config"
            config.mkdir()
            terminals = config / "xdg-terminals.list"
            terminals.write_text("fallback.desktop\n")
            env = dict(os.environ, HOME=str(root), XDG_CONFIG_HOME=str(config),
                       XDG_DATA_HOME=str(root / "data"), XDG_DATA_DIRS=str(root / "empty"),
                       PATH=f"{binary}:{os.environ['PATH']}", LOG=str(log),
                       XDG_CURRENT_DESKTOP="ubuntu:GNOME", DBUS_SESSION_BUS_ADDRESS="test")
            args = ["sh", str(SCRIPT), "ghostty_ghostty.desktop", "zen.desktop"]
            for _ in range(2):
                subprocess.run(args, env=env, check=True, capture_output=True, text=True)
                self.assertEqual(terminals.read_text(),
                                 "ghostty_ghostty.desktop\nfallback.desktop\n"
                                 "/execarg_default:ghostty_ghostty.desktop:-e\n")
            calls = log.read_text()
            self.assertIn("gsettings set org.gnome.desktop.default-applications.terminal exec xdg-terminal-exec", calls)
            self.assertIn("xdg-settings set default-web-browser zen.desktop", calls)
            for mime in ("x-scheme-handler/http", "x-scheme-handler/https", "text/html", "application/xhtml+xml"):
                self.assertIn(f"xdg-mime default zen.desktop {mime}", calls)
            log.write_text("")
            before = terminals.read_text()
            result = subprocess.run(args[:-1] + ["missing.desktop"], env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Missing desktop entry", result.stderr)
            self.assertEqual(terminals.read_text(), before)
            self.assertEqual(log.read_text(), "")
            result = subprocess.run(["sh", str(SCRIPT)], env=env, check=True, capture_output=True, text=True)
            self.assertIn("Skipping", result.stdout)
            result = subprocess.run(args, env=dict(env, DBUS_SESSION_BUS_ADDRESS=""),
                                    check=True, capture_output=True, text=True)
            self.assertIn("Skipping", result.stdout)
            self.assertEqual(log.read_text(), "")
