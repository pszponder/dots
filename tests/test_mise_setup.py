"""Offline integration checks: python3 -m unittest discover -s tests -v."""
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]
MISE = shutil.which('mise')


class MiseSetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dots setup ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / 'home'
        self.home.mkdir()
        self.repo = self.root / 'checkout "quoted"'
        self.repo.mkdir()
        for name in ('mise.toml', 'install.sh'):
            shutil.copy(REPO / name, self.repo / name)
        for name in ('scripts', 'dots'):
            (self.repo / name).symlink_to(REPO / name, target_is_directory=True)
        self.config = self.home / '.config/mise'
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(('MISE_', 'XDG_', 'DOTFILES_'))}
        self.env.update(HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CACHE_HOME=str(self.root / 'cache'),
                        XDG_DATA_HOME=str(self.root / 'data'),
                        XDG_STATE_HOME=str(self.root / 'state'),
                        MISE_TRUSTED_CONFIG_PATHS=str(self.root), MISE_OFFLINE='1')

    def run_command(self, *args):
        result = subprocess.run(args, env=self.env, cwd='/tmp', text=True,
                                capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def configure(self):
        self.run_command('sh', str(self.repo / 'scripts/bootstrap/configure_mise.sh'),
                         str(self.repo))

    def test_context_backups_and_repeat_setup(self):
        self.config.mkdir(parents=True)
        (self.config / 'config.toml').write_text('# existing configuration\n')
        (self.config / 'config.local.toml').write_text('# keep local overrides\n')
        self.configure()
        context = tomllib.loads((self.config / 'conf.d/00-dotfiles-context.toml').read_text())
        self.assertEqual(context['vars']['dotfiles_repo'], str(self.repo))
        self.assertEqual(context['settings']['dotfiles']['root'], str(self.repo / 'dots'))
        backups = list(self.config.glob('.dotfiles-backup.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'config.toml').read_text(), '# existing configuration\n')
        self.configure()
        self.assertEqual(list(self.config.glob('.dotfiles-backup.*')), backups)
        self.assertEqual((self.config / 'config.local.toml').read_text(), '# keep local overrides\n')
        self.assertEqual((self.config / 'dotfiles').resolve(), self.repo)

    @unittest.skipUnless(MISE, 'mise is required for config integration checks')
    def test_profiles_bootstrap_and_updates_from_outside_checkout(self):
        self.configure()
        (self.config / 'config.local.toml').write_text(
            '[vars]\ngit_name="Test"\ngit_email="test@example.com"\n')
        for profile in ('server', 'workstation'):
            with self.subTest(profile=profile):
                configs = self.run_command(MISE, '-E', profile, 'config', '--json')
                self.assertIn(f'config.{profile}.toml', configs)
                other = 'server' if profile == 'workstation' else 'workstation'
                self.assertNotIn(f'config.{other}.toml', configs)
                # Skip version resolution/downloads; exercise all bootstrap path rendering.
                output = self.run_command(MISE, '-E', profile, 'bootstrap',
                                          '--dry-run', '--skip', 'tools')
                self.assertNotIn('fedora_development_tools.sh', output)
                self.assertIn('create_ssh_keys.sh', output)
                self.assertIn('flox_install.sh', output)
                self.assertIn('flatpak_install.sh' if profile == 'workstation'
                              else 'nerdfonts_install.sh', output)
                # Also check the root checkout-context override.
                self.run_command(MISE, '-C', str(self.repo), '-E', profile,
                                 'bootstrap', '--dry-run', '--skip', 'tools')
                self.env.update(DOTFILES_REPO=str(self.repo), DOTFILES_PROFILE=profile)
                output = self.run_command('bash', str(self.repo / 'dots/.local/bin/system-update'),
                                          '--dry-run')
                self.assertIn(f'-E {profile} install --yes', output)
                self.assertIn(f'-E {profile} upgrade --yes', output)
                self.assertIn('bootstrap packages upgrade --yes', output)

    @unittest.skipUnless(MISE, 'mise is required for dotfile integration checks')
    def test_home_group_deployment(self):
        self.configure()
        (self.config / 'config.local.toml').write_text(
            '[vars]\ngit_name="Test"\ngit_email="test@example.com"\n')
        self.run_command(MISE, '-E', 'server', 'dot', 'apply')
        for source in (REPO / 'dots').rglob('*'):
            relative = source.relative_to(REPO / 'dots')
            if not source.is_file():
                continue
            target = self.home / relative
            if source.suffix == '.tera':
                rendered = target.with_suffix('')
                self.assertTrue(rendered.is_file(), str(rendered))
                self.assertFalse(rendered.is_symlink())
                self.assertFalse(target.exists())
            else:
                self.assertTrue(target.is_symlink(), str(target))
                self.assertEqual(target.resolve(), source.resolve())
        self.assertIn('Test', (self.home / '.config/git/config').read_text())
        self.assertIn(str(self.repo), (self.home / '.config/env.sh').read_text())
        self.assertTrue((self.config / 'config.toml').is_symlink())
        self.assertFalse((self.config / 'config.local.toml').is_symlink())
        # Add a config after setup, using an isolated source tree.
        sources = self.root / 'sources'
        shutil.copytree(REPO / 'dots', sources)
        fragment = sources / '.config/mise/conf.d/extra.toml'
        fragment.parent.mkdir(parents=True)
        fragment.write_text('[vars]\ngroup_extra = "deployed"\n')
        context = self.config / 'conf.d/00-dotfiles-context.toml'
        original_context = context.read_text()
        local = self.config / 'config.local.toml'
        local.write_text(local.read_text() +
                         '\n[settings.dotfiles]\nroot = ' + json.dumps(str(sources)) + '\n')
        local_config = local.read_text()
        self.run_command(MISE, '-E', 'server', 'dot', 'apply')
        deployed = self.config / 'conf.d/extra.toml'
        self.assertTrue(deployed.is_symlink())
        self.assertEqual(deployed.resolve(), fragment)
        self.assertEqual((self.config / 'config.local.toml').read_text(), local_config)
        self.assertFalse(context.is_symlink())
        self.assertEqual(context.read_text(), original_context)
        self.assertIn('group_extra', self.run_command(MISE, '-E', 'server', 'vars'))

    def test_installer_links_configuration_before_bootstrap(self):
        fake_bin = self.root / 'bin'
        fake_bin.mkdir()
        fake_mise = fake_bin / 'mise'
        fake_mise.write_text('''#!/bin/sh
set -eu
config="$HOME/.config/mise"
test -L "$config/config.toml"
test -L "$config/dotfiles"
test -f "$config/conf.d/00-dotfiles-context.toml"
printf '%s\\n' "$*" >> "$HOME/mise-calls"
''')
        fake_mise.chmod(0o755)
        self.env['PATH'] = str(fake_bin) + ':' + self.env['PATH']
        self.run_command('sh', str(self.repo / 'install.sh'), 'server')
        calls = (self.home / 'mise-calls').read_text().splitlines()
        self.assertEqual(calls, ['trust',
                                 '-E server bootstrap --dry-run', '-E server bootstrap',
                                 '-E server bootstrap status'])
        # A standalone downloaded installer must work before logging helpers exist.
        downloaded = self.root / 'downloaded-install.sh'
        shutil.copy(self.repo / 'install.sh', downloaded)
        (self.repo / '.git').mkdir()
        self.env['DOTFILES_REPO_DIR'] = str(self.repo)
        self.run_command('sh', str(downloaded))
        calls = (self.home / 'mise-calls').read_text().splitlines()
        self.assertEqual(calls[-4:], ['trust',
                                     '-E workstation bootstrap --dry-run',
                                     '-E workstation bootstrap',
                                     '-E workstation bootstrap status'])


if __name__ == '__main__':
    unittest.main()
