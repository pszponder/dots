#!/usr/bin/env python3
"""Install saved Ptyxis profiles without replacing other profiles."""
import argparse
import ast
import json
import os
import shutil
import subprocess

SCHEMA = 'org.gnome.Ptyxis'
PROFILES = {
    'mocha': '95894cfd82f7430daf6e84d168bc34f5',
    'latte': 'de8a908183524ce495195de655ad9361',
}


def gsettings(*args):
    return subprocess.check_output(['gsettings', *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('flavor', nargs='?', choices=('mocha', 'latte'), default='mocha')
    args = parser.parse_args()
    if not os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
        print('Skipping Ptyxis setup: run after desktop login.')
        return
    if not shutil.which('gsettings') or SCHEMA not in gsettings('list-schemas').splitlines():
        print('Skipping Ptyxis setup: install Ptyxis first.')
        return
    if os.getuid() == 0:
        parser.error('Run as your desktop login user, not root.')
    existing = ast.literal_eval(gsettings('get', SCHEMA, 'profile-uuids').removeprefix('@as '))
    for flavor, uuid in PROFILES.items():
        schema = f'org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/{uuid}/'
        gsettings('set', schema, 'label', json.dumps(f'catppuccin-{flavor}'))
        gsettings('set', schema, 'palette', json.dumps(f'Catppuccin {flavor.capitalize()}'))
        if uuid not in existing:
            existing.append(uuid)
    gsettings('set', SCHEMA, 'profile-uuids', json.dumps(existing))
    gsettings('set', SCHEMA, 'default-profile-uuid', json.dumps(PROFILES[args.flavor]))
    gsettings('set', SCHEMA, 'use-system-font', 'false')
    gsettings('set', SCHEMA, 'font-name', json.dumps('CaskaydiaCove Nerd Font Mono 12'))
    print(f'Configured Catppuccin profiles with CaskaydiaCove Nerd Font Mono 12; default: {args.flavor}.')


if __name__ == '__main__':
    main()
