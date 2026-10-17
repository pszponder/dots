"""Ptyxis setup preserves profiles and supports repeated switching."""
import importlib.util
import json
from pathlib import Path
import unittest
import tempfile
import os
import subprocess
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ptyxis', ROOT / 'scripts/bootstrap/configure_ptyxis.py')
terminal = importlib.util.module_from_spec(spec)
spec.loader.exec_module(terminal)


class TerminalTests(unittest.TestCase):
    def test_preserves_profiles_and_switches_without_duplicates(self):
        state = {(terminal.SCHEMA, 'profile-uuids'): ['existing-profile']}

        def settings(action, *args):
            if action == 'list-schemas':
                return terminal.SCHEMA
            schema, key = args[:2]
            if action == 'get':
                return repr(state[schema, key])
            state[schema, key] = json.loads(args[2])
            return ''

        with tempfile.TemporaryDirectory() as data_dir, patch.object(terminal, 'gsettings', side_effect=settings), patch.object(terminal.os, 'getuid', return_value=1000), patch.object(terminal.shutil, 'which', return_value='/usr/bin/gsettings'), patch.dict(terminal.os.environ, DBUS_SESSION_BUS_ADDRESS='test', XDG_DATA_HOME=data_dir):
            for flavor in ('mocha', 'latte', 'latte'):
                with patch('sys.argv', ['setup', flavor]):
                    terminal.main()
        self.assertEqual(state[terminal.SCHEMA, 'profile-uuids'], [
            'existing-profile', '95894cfd82f7430daf6e84d168bc34f5',
            'de8a908183524ce495195de655ad9361'])
        self.assertEqual(state[terminal.SCHEMA, 'default-profile-uuid'], 'de8a908183524ce495195de655ad9361')
        self.assertEqual(state[terminal.SCHEMA, 'font-name'], 'CaskaydiaCove Nerd Font Mono 12')
        self.assertFalse(state[terminal.SCHEMA, 'use-system-font'])
        for flavor, uuid in terminal.PROFILES.items():
            schema = f'org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/{uuid}/'
            self.assertEqual(state[schema, 'palette'], f'Catppuccin {flavor.capitalize()}')

    def test_no_session_skips(self):
        with patch.dict(terminal.os.environ, {}, clear=True), patch.object(terminal, 'gsettings') as settings, patch('sys.argv', ['setup']):
            terminal.main()
        settings.assert_not_called()

    @unittest.skipUnless(terminal.shutil.which('gsettings'), 'gsettings required')
    def test_installed_schema_accepts_settings(self):
        # Exercise real GVariant parsing and installed schemas without writing dconf.
        env = dict(os.environ, GSETTINGS_BACKEND='memory')
        if terminal.SCHEMA not in subprocess.check_output(['gsettings', 'list-schemas'], env=env, text=True).splitlines():
            self.skipTest('Ptyxis schemas not installed')
        original = terminal.gsettings
        def settings(*args):
            if args[0] == 'get' and args[2] == 'profile-uuids':
                return '@as []'
            with patch.dict(os.environ, env):
                return original(*args)
        with tempfile.TemporaryDirectory() as data_dir, patch.dict(os.environ, DBUS_SESSION_BUS_ADDRESS='test', XDG_DATA_HOME=data_dir), patch.object(terminal.os, 'getuid', return_value=1000), patch.object(terminal, 'gsettings', side_effect=settings), patch('sys.argv', ['setup', 'latte']):
            terminal.main()

    @unittest.skipUnless(terminal.shutil.which('gresource') and terminal.shutil.which('ptyxis'), 'Ptyxis resources required')
    def test_builtin_palettes_exist(self):
        binary = terminal.shutil.which('ptyxis')
        for flavor in terminal.PROFILES:
            resource = f'/org/gnome/Ptyxis/palettes/Catppuccin {flavor.capitalize()}.palette'
            palette = subprocess.check_output(['gresource', 'extract', binary, resource], text=True)
            self.assertIn(f'Name=Catppuccin {flavor.capitalize()}', palette)
