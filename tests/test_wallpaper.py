"""Wallpaper checks use isolated homes and fake desktop commands."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/gui/configure_wallpaper.sh"


class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'home with spaces'
        self.image = self.home / 'Pictures/wallpapers/catppuccin-mocha.png'
        self.image.parent.mkdir(parents=True)
        self.image.touch()
        self.bin = Path(self.tmp.name) / 'bin'
        self.bin.mkdir()
        self.log = Path(self.tmp.name) / 'calls'
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CURRENT_DESKTOP='', XDG_SESSION_DESKTOP='', WAYLAND_DISPLAY='', DISPLAY='',
                        PATH=str(self.bin) + ':' + os.environ['PATH'], CALLS=str(self.log))

    def fake(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body)
        path.chmod(0o755)

    def run_script(self, desktop='', display='wayland-1'):
        self.env.update(XDG_CURRENT_DESKTOP=desktop, WAYLAND_DISPLAY=display)
        result = subprocess.run(['sh', str(SCRIPT)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_headless_and_unsupported_skip(self):
        self.assertIn('No graphical session', self.run_script('GNOME', ''))
        self.assertIn('Unsupported desktop', self.run_script('KDE'))
        self.assertFalse(self.log.exists())

    def test_gnome_light_dark_and_uri(self):
        self.fake('gsettings', 'if [ "$1" = list-keys ]; then echo picture-uri-dark; else printf "%s\\n" "$@" >> "$CALLS"; fi\n')
        self.run_script('ubuntu:GNOME')
        calls = self.log.read_text()
        self.assertIn('picture-uri-dark', calls)
        self.assertIn(self.image.as_uri(), calls)
        self.assertIn('zoom', calls)

    def test_omarchy_command(self):
        self.fake('omarchy', 'printf "%s\\n" "$@" >> "$CALLS"\n')
        self.run_script('Hyprland')
        self.assertEqual(self.log.read_text().splitlines(), ['theme', 'bg', 'set', str(self.image)])

    def test_cosmic_shared_background_backup_and_repeat(self):
        config = self.home / '.config/cosmic/com.system76.CosmicBackground/v1'
        config.mkdir(parents=True)
        (config / 'all').write_text('original')
        self.run_script('COSMIC')
        content = (config / 'all').read_text()
        self.assertIn(str(self.image), content)
        self.assertIn('source: Path(', content)
        self.assertEqual((config / 'same-on-all').read_text(), 'true\n')
        self.run_script('COSMIC')
        self.assertEqual((config / 'all').read_text(), content)
        self.assertEqual((config / 'all.before-dotfiles').read_text(), 'original')
