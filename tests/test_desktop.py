"""Exercise desktop setup without changing the real desktop."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/bootstrap/configure_desktop.sh"


class DesktopTests(unittest.TestCase):
    def test_wallpaper_and_optional_dark_mode(self):
        with tempfile.TemporaryDirectory(prefix="desktop setup ") as directory:
            root = Path(directory)
            image = root / "Pictures/wallpapers/catppuccin-mocha.png"
            image.parent.mkdir(parents=True)
            image.write_bytes(b"image")
            binary = root / "bin"
            binary.mkdir()
            for name, body in {
                "id": "echo 1000\n",
                "gsettings": 'if [ "$1" = list-keys ]; then\n'
                             '  printf "%s\\n" picture-uri picture-options\n'
                             '  [ "$DARK" = no ] || echo picture-uri-dark\n'
                             'else\n  printf "%s\\n" "$*" >> "$LOG"\nfi\n',
            }.items():
                path = binary / name
                path.write_text("#!/bin/sh\n" + body)
                path.chmod(0o755)
            log = root / "calls"
            env = dict(os.environ, HOME=str(root), PATH=f"{binary}:{os.environ['PATH']}",
                       LOG=str(log), XDG_CURRENT_DESKTOP="ubuntu:GNOME",
                       DBUS_SESSION_BUS_ADDRESS="test")
            for dark in ("yes", "no"):
                with self.subTest(dark=dark):
                    log.write_text("")
                    subprocess.run(["sh", str(SCRIPT)], env=dict(env, DARK=dark),
                                   check=True, capture_output=True, text=True)
                    calls = log.read_text().splitlines()
                    self.assertIn(f"set org.gnome.desktop.background picture-uri {image.as_uri()}", calls)
                    self.assertEqual(any("picture-uri-dark" in call for call in calls), dark == "yes")
                    self.assertIn("set org.gnome.desktop.background picture-options zoom", calls)
            log.write_text("")
            result = subprocess.run(["sh", str(SCRIPT)],
                                    env=dict(env, XDG_CURRENT_DESKTOP="COSMIC"),
                                    check=True, capture_output=True, text=True)
            self.assertIn("Skipping", result.stdout)
            self.assertEqual(log.read_text(), "")
