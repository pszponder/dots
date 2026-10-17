"""Replacement consent and Git preservation without touching the real home."""
import os
from pathlib import Path
import pty
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / 'scripts/bootstrap'


class ReplacementTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(('MISE_', 'DOTFILES_', 'XDG_'))}
        self.env.update(HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'))

    def test_confirmation_terminal_answers(self):
        for answer, success in [('y', True), ('n', False), ('', False)]:
            with self.subTest(answer=answer):
                master, slave = pty.openpty()
                try:
                    process = subprocess.Popen(['sh', str(SCRIPTS / 'confirm_replacements.sh')],
                                               stdin=slave, stdout=slave, stderr=slave, env=self.env)
                    os.write(master, (answer + '\n').encode())
                    self.assertEqual(process.wait(timeout=5) == 0, success)
                finally:
                    os.close(master)
                    os.close(slave)

    def test_noninteractive_requires_explicit_consent(self):
        args = ['sh', str(SCRIPTS / 'confirm_replacements.sh')]
        rejected = subprocess.run(args, stdin=subprocess.DEVNULL, capture_output=True, env=self.env)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertEqual(subprocess.run(args + ['--yes'], env=self.env).returncode, 0)

    def test_configuration_generation_without_python_and_rejection(self):
        config = self.home / '.config/mise'
        config.mkdir(parents=True)
        target = config / 'config.toml'
        target.write_text('# local\n')
        checkout = self.home / 'checkout "quotes" \\ slash'
        checkout.symlink_to(ROOT, target_is_directory=True)
        args = ['sh', str(SCRIPTS / 'configure_mise.sh'), str(checkout), 'server']
        rejected = subprocess.run(args, env=self.env, stdin=subprocess.DEVNULL, capture_output=True)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertEqual(target.read_text(), '# local\n')
        # A Python executable that fails proves setup does not invoke it.
        binaries = self.home / 'bin'
        binaries.mkdir()
        for name in ('python', 'python3'):
            executable = binaries / name
            executable.write_text('#!/bin/sh\nexit 99\n')
            executable.chmod(0o755)
        self.env['PATH'] = str(binaries) + ':' + self.env['PATH']
        subprocess.run(args + ['--yes'], env=self.env, check=True, capture_output=True)
        context = tomllib.loads((config / 'conf.d/01-dotfiles-machine.toml').read_text())
        self.assertEqual(context['vars']['dotfiles_repo'], str(checkout))
        self.assertEqual(list(config.glob('.dotfiles-backup.*')), [])

    def test_normal_attempt_and_single_force_retry(self):
        binaries = self.home / 'bin'
        binaries.mkdir()
        mise = binaries / 'mise'
        mise.write_text("""#!/bin/sh
printf '%s\\n' "$*" >> "$HOME/calls"
case "$*" in
  *--force*) exit "${FORCE_RESULT:-0}" ;;
  *) exit "${NORMAL_RESULT:-1}" ;;
esac
""")
        mise.chmod(0o755)
        self.env['PATH'] = str(binaries) + ':' + self.env['PATH']
        calls = self.home / 'calls'
        for action, normal, forced in [
            ('bootstrap', '-E server bootstrap --yes', '-E server bootstrap --yes --force-dotfiles'),
            ('dotfiles', '-E server dot apply --yes', '-E server dot apply --yes --force'),
        ]:
            args = ['sh', str(SCRIPTS / 'retry_mise.sh'), action, '-E', 'server']
            with self.subTest(action=action):
                self.env['NORMAL_RESULT'] = '0'
                subprocess.run(args, env=self.env, check=True, capture_output=True)
                self.assertEqual(calls.read_text().splitlines(), [normal])
                calls.unlink()
                self.env['NORMAL_RESULT'] = '1'
                rejected = subprocess.run(args, env=self.env, stdin=subprocess.DEVNULL,
                                          capture_output=True)
                self.assertNotEqual(rejected.returncode, 0)
                self.assertEqual(calls.read_text().splitlines(), [normal])
                calls.unlink()
                self.env['DOTFILES_YES'] = '1'
                subprocess.run(args, env=self.env, check=True, capture_output=True)
                self.assertEqual(calls.read_text().splitlines(), [normal, forced])
                calls.unlink()
                self.env['FORCE_RESULT'] = '7'
                failed = subprocess.run(args, env=self.env, capture_output=True)
                self.assertEqual(failed.returncode, 7)
                self.assertEqual(calls.read_text().splitlines(), [normal, forced])
                calls.unlink()
                self.env.pop('DOTFILES_YES')
                self.env.pop('FORCE_RESULT')

    def test_git_defaults_preserve_local_values_and_repeat(self):
        config = self.home / '.config/git'
        config.mkdir(parents=True)
        (config / 'defaults').write_text('[core]\n editor = nvim\n')
        (config / 'config').write_text('[core]\n editor = local-editor\n')
        (config / 'dotfiles-identity').write_text('[user]\n name = Default\n')
        target = self.home / '.gitconfig'
        target.write_text('[user]\n name = Local\n[credential]\n helper = local-helper\n')
        args = ['sh', str(SCRIPTS / 'configure_git.sh')]
        subprocess.run(args, env=self.env, check=True)
        first = target.read_text()
        subprocess.run(args, env=self.env, check=True)
        self.assertEqual(target.read_text(), first)
        for key, expected in [('user.name', 'Local'), ('core.editor', 'local-editor'),
                              ('credential.helper', 'local-helper')]:
            result = subprocess.run(['git', 'config', '--includes', '--get', key],
                                    env=self.env, cwd=self.home, text=True, capture_output=True, check=True)
            self.assertEqual(result.stdout.strip(), expected)
