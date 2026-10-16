"""Offline checks for distribution selection and desktop installation policy."""
from pathlib import Path
import os
import pty
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]
DISTROS = ("ubuntu", "debian", "fedora", "arch", "ublue")


class WorkstationProfileTests(unittest.TestCase):
    def test_interactive_profile_menu(self):
        source = (REPO / "install.sh").read_text().rsplit('main "$@"', 1)[0]
        harness = source + '\nlog_error() { printf "%s\\n" "$*" >&2; }\nchoose_profile\n'
        for selection, expected in (
            ("2", "server"),
            *((str(index), f"workstation-{distro}")
              for index, distro in enumerate(DISTROS, start=3)),
            ("workstation-fedora", "workstation-fedora"),
        ):
            with self.subTest(selection=selection):
                master, slave = pty.openpty()
                try:
                    os.write(master, (selection + "\n").encode())
                    result = subprocess.run(
                        ["sh", "-c", harness], stdin=slave,
                        capture_output=True, text=True, timeout=10,
                    )
                finally:
                    os.close(slave)
                    os.close(master)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), expected)
                for distro in DISTROS:
                    self.assertIn(f"workstation-{distro}", result.stderr)

    def test_selection_and_unsupported_systems(self):
        source = (REPO / "install.sh").read_text().rsplit('main "$@"', 1)[0]
        cases = [
            *((f"ID={distro}\nID_LIKE=debian\n", "workstation", f"workstation-{distro}")
              for distro in DISTROS),
            ('ID=pop\nID_LIKE="ubuntu debian"\n', "workstation", "workstation-ubuntu"),
            ('ID=linuxmint\nID_LIKE=debian\n', "workstation", "workstation-debian"),
            ('ID=derivative\nID_LIKE=fedora\n', "workstation", "workstation-fedora"),
            ('ID=manjaro\nID_LIKE=arch\n', "workstation", "workstation-arch"),
            ('ID=bluefin\nID_LIKE=fedora\n', "workstation", "workstation-ublue"),
            ('ID=bazzite\nID_LIKE=fedora\n', "workstation", "workstation-ublue"),
            ('ID=aurora\nID_LIKE=fedora\n', "workstation", "workstation-ublue"),
            ('ID=custom\nID_LIKE="fedora ublue"\n', "workstation", "workstation-ublue"),
            ('ID=unknown\n', "workstation", None),
            ('ID=unknown\n', "workstation-fedora", "workstation-fedora"),
            ('ID=unknown\n', "server", "server"),
            ('ID=unknown\n', "", None),
            ('ID=ubuntu\n', "workstation-invalid", None),
        ]
        with tempfile.TemporaryDirectory() as directory:
            release = Path(directory) / "os-release"
            harness = source.replace('/etc/os-release', str(release))
            harness += '\nlog_error() { printf "%s\\n" "$*" >&2; }\nchoose_profile "$1"\n'
            for metadata, selection, expected in cases:
                with self.subTest(metadata=metadata, selection=selection):
                    release.write_text(metadata)
                    result = subprocess.run(
                        ['sh', '-c', harness, 'test-installer', selection],
                        stdin=subprocess.DEVNULL, capture_output=True, text=True,
                    )
                    if expected:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertEqual(result.stdout.strip(), expected)
                    else:
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn('profile', result.stderr)

    def test_application_sources_and_hooks(self):
        for distro in DISTROS:
            with self.subTest(distro=distro):
                profile = f"workstation-{distro}"
                config = tomllib.loads((REPO / f"bootstrap/mise.{profile}.toml").read_text())
                self.assertEqual(config['vars']['dotfiles_profile'], profile)
                bootstrap = config['bootstrap']
                packages = bootstrap['packages']
                names = [key.split(':', 1)[1] for key in packages]
                self.assertEqual(len(names), len(set(names)))
                if distro == "ublue":
                    self.assertEqual(set(key.split(":")[0] for key in packages), {"flatpak", "flatpak-user", "brew-cask"})
                    self.assertEqual(sum(key.startswith("brew-cask:") for key in packages), 3)
                    self.assertIn("--ublue", str(bootstrap["hooks"]))
                    self.assertNotIn("post-packages", bootstrap["hooks"])
                    continue
                manager = {'ubuntu': 'apt', 'debian': 'apt', 'fedora': 'dnf', 'arch': 'pacman'}[distro]
                allowed = {manager, 'flatpak', 'flatpak-user', 'snap' if distro == 'ubuntu' else 'aur' if distro == 'arch' else manager}
                if distro == 'arch':
                    allowed = {'pacman', 'aur'}
                    for app in ('obsidian', 'discord', 'podman-desktop', 'zed'):
                        self.assertIn(f'pacman:{app}', packages)
                    self.assertIn('aur:zen-browser-bin', packages)
                self.assertTrue(all(key.split(':')[0] in allowed for key in packages))
                for app in ('obsidian', 'discord', 'code', 'ghostty'):
                    choices = {
                        'obsidian': ('snap:obsidian', 'flatpak:md.obsidian.Obsidian', 'pacman:obsidian'),
                        'discord': ('snap:discord', 'flatpak:com.discordapp.Discord', 'pacman:discord'),
                        'code': ('snap:code', 'flatpak:com.visualstudio.code', 'aur:visual-studio-code-bin'),
                        'ghostty': ('snap:ghostty', 'apt:ghostty', 'dnf:ghostty', 'pacman:ghostty'),
                    }[app]
                    self.assertEqual(sum(key in packages for key in choices), 1)
                    if distro == 'ubuntu':
                        self.assertIn(f'snap:{app}', packages)
                pre_hooks = bootstrap['hooks'].get('pre-packages', [])
                self.assertTrue(all('flatpak_install.sh' in hook for hook in pre_hooks))
                self.assertEqual('flatpak_install.sh' in '\n'.join(pre_hooks), distro != 'arch')
                hooks = '\n'.join(bootstrap['hooks'].get('post-packages', []))
                self.assertEqual('zed_install.sh' in hooks, distro != 'arch')
                if distro in ('ubuntu', 'debian'):
                    self.assertNotIn('apt:helium-bin', packages)
                self.assertEqual('helium_repo.sh' in hooks, distro in ('ubuntu', 'debian'))
                self.assertEqual('brave_origin_install.sh' in hooks, distro != 'arch')
                self.assertEqual('yaak_install.sh' in hooks, distro != 'arch')
                self.assertEqual('dnf' in bootstrap, distro == 'fedora')
        server = tomllib.loads((REPO / 'bootstrap/mise.server.toml').read_text())
        self.assertTrue(server['bootstrap']['packages'])
        self.assertFalse((REPO / 'bootstrap/mise.workstation.toml').exists())

    def test_update_preview_accepts_full_profiles_and_rejects_legacy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / '.config/mise'
            config.mkdir(parents=True)
            (config / 'config.toml').symlink_to(REPO / 'dots/.config/mise/config.toml')
            fake_mise = root / 'mise'
            fake_mise.write_text('#!/bin/sh\nexit 99\n')
            fake_mise.chmod(0o755)
            atomic = root / 'rpm-ostree'
            atomic.write_text('#!/bin/sh\nexit 99\n')
            atomic.chmod(0o755)
            env = {key: value for key, value in os.environ.items()
                   if not key.startswith(('MISE_', 'XDG_', 'DOTFILES_'))}
            env.update(HOME=str(root), PATH=f'{root}:/usr/bin:/bin', DOTFILES_REPO=str(REPO))
            for profile in ('server', *(f'workstation-{distro}' for distro in DISTROS), 'workstation'):
                with self.subTest(profile=profile):
                    env['DOTFILES_PROFILE'] = profile
                    result = subprocess.run(
                        ['bash', str(REPO / 'dots/.local/bin/system-update'), '--dry-run'],
                        env=env, cwd='/tmp', capture_output=True, text=True,
                    )
                    if profile == 'workstation':
                        self.assertEqual(result.returncode, 2)
                        self.assertIn('reload your shell', result.stderr)
                        self.assertNotIn('apt-get', result.stdout)
                    else:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertIn(f'-E {profile} install --yes', result.stdout)
                        self.assertIn(f'-E {profile} bootstrap packages upgrade --yes', result.stdout)
