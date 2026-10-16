"""Exercise device setup without changing host groups, devices, or services."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class KanataSetupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="dots kanata ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.log = self.root / "commands"
        config = self.root / ".config"
        for name in ("systemd/user/kanata.service", "kanata/kanata.kbd"):
            path = config / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch()
        binaries = self.root / "bin"
        binaries.mkdir()
        mock = binaries / "mock"
        mock.write_text("""#!/usr/bin/python3
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['HOME'])
with (root / 'commands').open('a') as log:
    log.write(json.dumps([name, *args]) + '\\n')
if name == 'uname':
    print(os.environ.get('TEST_OS', 'Linux'))
elif name == 'id':
    print({'-u': '1000', '-un': 'piotr', '-nG': os.environ.get('TEST_GROUPS', 'piotr')}[args[0]])
elif name == 'getent':
    sys.exit(0 if (root / args[-1]).exists() else 2)
elif name == 'sudo':
    if args[0] == 'groupadd':
        (root / args[-1]).touch()
    elif args[0] == 'tee':
        (root / pathlib.Path(args[-1]).name).write_text(sys.stdin.read())
    elif args[0] == 'modprobe' and os.environ.get('TEST_FAIL_MODULE'):
        sys.exit(1)
""")
        mock.chmod(0o755)
        for name in ("uname", "id", "getent", "sudo", "systemctl"):
            (binaries / name).symlink_to(mock)
        self.env = dict(os.environ, HOME=str(self.root), XDG_CONFIG_HOME=str(config),
                        PATH=f"{binaries}:/usr/bin:/bin")

    def configure(self, **env):
        return subprocess.run(
            ["sh", str(REPO / "scripts/bootstrap/configure_kanata.sh")],
            env={**self.env, **env}, text=True, capture_output=True,
        )

    def test_new_groups_enable_service_and_require_reboot(self):
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Reboot", result.stdout)
        self.assertEqual((self.root / "kanata.conf").read_text(), "uinput\n")
        self.assertIn('MODE="0660", GROUP="uinput"',
                      (self.root / "99-kanata.rules").read_text())
        commands = self.log.read_text()
        self.assertIn('["sudo", "usermod", "-aG", "input,uinput", "piotr"]', commands)
        self.assertIn('["systemctl", "--user", "enable", "kanata.service"]', commands)
        self.assertNotIn('"restart"', commands)

    def test_repeat_setup_reuses_groups_and_restarts_service(self):
        self.configure()
        self.log.write_text("")
        result = self.configure(TEST_GROUPS="piotr input uinput")
        self.assertEqual(result.returncode, 0, result.stderr)
        commands = self.log.read_text()
        self.assertNotIn('"groupadd"', commands)
        self.assertIn('["systemctl", "--user", "restart", "kanata.service"]', commands)

    def test_module_failure_does_not_enable_service(self):
        result = self.configure(TEST_FAIL_MODULE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('"systemctl"', self.log.read_text())

    def test_non_linux_skips_system_changes(self):
        result = self.configure(TEST_OS="Darwin")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Linux only", result.stdout)
        self.assertNotIn('"sudo"', self.log.read_text())
