"""Offline integration checks for checkout-local hook setup."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class GitHookSetupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="dots hooks ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.script = self.root / "scripts/bootstrap/configure_git_hooks.sh"
        self.script.parent.mkdir(parents=True)
        shutil.copy(REPO / "scripts/bootstrap/configure_git_hooks.sh", self.script)

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, env=self.env,
                              text=True, capture_output=True, check=True).stdout.strip()

    def configure(self):
        return subprocess.run(["sh", str(self.script)], cwd="/tmp", env=self.env,
                              text=True, capture_output=True, check=True)

    def test_setup_and_repeat(self):
        self.git("init", "-q")
        for _ in range(2):
            self.configure()
            self.assertEqual(self.git("config", "--local", "--get", "core.hooksPath"), ".githooks")

    def test_preserves_custom_path(self):
        self.git("init", "-q")
        self.git("config", "core.hooksPath", "custom-hooks")
        self.assertIn("Keeping existing", self.configure().stderr)
        self.assertEqual(self.git("config", "--get", "core.hooksPath"), "custom-hooks")

    def test_preserves_local_hook(self):
        self.git("init", "-q")
        hook = self.root / ".git/hooks/pre-commit"
        hook.write_text("#!/bin/sh\nexit 0\n")
        self.assertIn("Keeping existing", self.configure().stderr)
        self.assertEqual(hook.read_text(), "#!/bin/sh\nexit 0\n")
        self.assertNotIn("core.hookspath", self.git("config", "--local", "--list"))

    def test_archive_skips_setup(self):
        self.assertIn("no Git metadata", self.configure().stdout)

    def test_linked_worktree(self):
        self.git("init", "-q")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "--allow-empty", "-m", "fixture")
        worktree = self.root / "linked checkout"
        self.git("worktree", "add", "-b", "linked", str(worktree))
        script = worktree / "scripts/bootstrap/configure_git_hooks.sh"
        script.parent.mkdir(parents=True)
        shutil.copy(self.script, script)
        subprocess.run(["sh", str(script)], env=self.env, check=True, capture_output=True)
        self.assertEqual(self.git("-C", str(worktree), "config", "--get", "core.hooksPath"), ".githooks")
