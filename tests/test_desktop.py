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
                             '  if [ "$2" = org.gnome.desktop.interface ]; then\n'
                             '    echo color-scheme\n'
                             '    [ "$DARK" = no ] || echo accent-color\n'
                             '  else\n'
                             '  printf "%s\\n" picture-uri picture-options\n'
                             '  [ "$DARK" = no ] || echo picture-uri-dark\n'
                             '  fi\n'
                             'elif [ "$1" = list-schemas ]; then\n'
                             '  [ "$DARK" = no ] || printf "%s\\n" org.gnome.shell.extensions.dash-to-dock org.gnome.shell.extensions.tiling-assistant\n'
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
                    self.assertEqual("set org.gnome.desktop.interface accent-color purple" in calls, dark == "yes")
                    self.assertIn("set org.gnome.desktop.interface color-scheme prefer-dark", calls)
                    self.assertIn("set org.gnome.desktop.background picture-options zoom", calls)
                    self.assertIn("set org.gnome.mutter dynamic-workspaces false", calls)
                    self.assertIn("set org.gnome.desktop.wm.preferences num-workspaces 9", calls)
                    for number in range(1, 10):
                        self.assertIn(f"set org.gnome.shell.keybindings switch-to-application-{number} []", calls)
                        self.assertIn(f"set org.gnome.desktop.wm.keybindings switch-to-workspace-{number} ['<Super>{number}']", calls)
                        self.assertIn(f"set org.gnome.desktop.wm.keybindings move-to-workspace-{number} ['<Super><Shift>{number}']", calls)
                    for action in ("n", "w", "s", "e"):
                        self.assertIn(f"set org.gnome.desktop.wm.keybindings move-to-side-{action} []", calls)
                    tiling_calls = [call for call in calls if "extensions.tiling-assistant" in call]
                    self.assertEqual(tiling_calls, [
                        "set org.gnome.shell.extensions.tiling-assistant tile-left-half ['<Super><Shift>h', '<Super>Left', '<Super>KP_4']",
                        "set org.gnome.shell.extensions.tiling-assistant tile-bottom-half ['<Super>KP_2']",
                        "set org.gnome.shell.extensions.tiling-assistant tile-top-half ['<Super>KP_8']",
                        "set org.gnome.shell.extensions.tiling-assistant tile-right-half ['<Super><Shift>l', '<Super>Right', '<Super>KP_6']",
                    ] if dark == "yes" else [])
                    for schema, action, binding in (
                        ("desktop.wm.keybindings", "minimize", "['<Super><Shift>j', '<Alt>F9']"),
                        ("desktop.wm.keybindings", "switch-windows", "['<Super>l', '<Alt>Tab']"),
                        ("desktop.wm.keybindings", "switch-windows-backward", "['<Super>h', '<Shift><Alt>Tab']"),
                        ("desktop.wm.keybindings", "close", "['<Super>q', '<Alt>F4']"),
                        ("desktop.wm.keybindings", "maximize", "['<Super><Shift>k']"),
                        ("desktop.wm.keybindings", "toggle-maximized", "['<Super>m', '<Alt>F10']"),
                        ("settings-daemon.plugins.media-keys", "terminal", "['<Super>Return', '<Primary><Alt>t']"),
                        ("settings-daemon.plugins.media-keys", "www", "['<Super><Shift>Return']"),
                        ("settings-daemon.plugins.media-keys", "home", "['<Super>f', '<Super>e']"),
                        ("settings-daemon.plugins.media-keys", "screensaver", "['<Super><Control>l']"),
                        ("shell.keybindings", "toggle-message-tray", "['<Super>v']"),
                    ):
                        self.assertIn(f"set org.gnome.{schema} {action} {binding}", calls)
                    dock_calls = [call for call in calls if "extensions.dash-to-dock" in call]
                    self.assertEqual(dock_calls, [
                        "set org.gnome.shell.extensions.dash-to-dock hot-keys false",
                        "set org.gnome.shell.extensions.dash-to-dock shortcut []",
                        "set org.gnome.shell.extensions.dash-to-dock dock-fixed false",
                        "set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM",
                        "set org.gnome.shell.extensions.dash-to-dock extend-height false",
                        "set org.gnome.shell.extensions.dash-to-dock show-mounts-network true",
                        "set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted true",
                    ] if dark == "yes" else [])
                    self.assertIn(
                        "set org.gnome.shell favorite-apps ['org.gnome.Nautilus.desktop', "
                        "'zen.desktop', 'helium.desktop', 'code_code.desktop', "
                        "'ghostty_ghostty.desktop', 'obsidian_obsidian.desktop', 'discord_discord.desktop']",
                        calls,
                    )
            log.write_text("")
            result = subprocess.run(["sh", str(SCRIPT)],
                                    env=dict(env, XDG_CURRENT_DESKTOP="COSMIC"),
                                    check=True, capture_output=True, text=True)
            self.assertIn("Skipping", result.stdout)
            self.assertEqual(log.read_text(), "")
