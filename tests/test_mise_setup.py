"""Offline integration checks: python3 -m unittest discover -s tests -v."""

import json
import os
import pty
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MISE = shutil.which("mise")


class MiseSetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dots setup ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.repo = self.root / 'checkout "quoted"'
        self.repo.mkdir()
        for name in (
            "mise.toml",
            "mise.server.toml",
            "mise.workstation.toml",
            "install.sh",
        ):
            shutil.copy(REPO / name, self.repo / name)
        for name in ("scripts", "dots"):
            (self.repo / name).symlink_to(REPO / name, target_is_directory=True)
        self.config = self.home / ".config/mise"
        self.env = {
            k: v
            for k, v in os.environ.items()
            if not k.startswith(("MISE_", "XDG_", "DOTFILES_"))
        }
        self.env.update(
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            XDG_CACHE_HOME=str(self.root / "cache"),
            XDG_DATA_HOME=str(self.root / "data"),
            XDG_STATE_HOME=str(self.root / "state"),
            MISE_TRUSTED_CONFIG_PATHS=str(self.root),
            MISE_OFFLINE="1",
        )

    def run_command(self, *args):
        result = subprocess.run(
            args, env=self.env, cwd="/tmp", text=True, capture_output=True
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def configure(self):
        self.run_command(
            "sh", str(self.repo / "scripts/bootstrap/configure_mise.sh"), str(self.repo)
        )

    def test_config_backups_and_repeat_setup(self):
        self.config.mkdir(parents=True)
        (self.config / "config.toml").write_text("# existing configuration\n")
        (self.config / "config.local.toml").write_text("# keep local overrides\n")
        self.configure()
        backups = list(self.config.glob(".dotfiles-backup.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(
            (backups[0] / "config.toml").read_text(), "# existing configuration\n"
        )
        self.configure()
        self.assertEqual(list(self.config.glob(".dotfiles-backup.*")), backups)
        self.assertEqual(
            (self.config / "config.local.toml").read_text(), "# keep local overrides\n"
        )
        self.assertFalse((self.config / "dotfiles").exists())
        self.assertFalse((self.config / "conf.d/00-dotfiles-context.toml").exists())

    @unittest.skipUnless(MISE and shutil.which("git"), "mise and git are required")
    def test_repository_bootstrap_without_global_preparation(self):
        # Exercise --from against a real local Git remote, without network or
        # package installation. Copy sources so deployed links use the clone.
        remote = self.root / "remote"
        remote.mkdir()
        for name in ("mise.toml", "mise.server.toml", "mise.workstation.toml"):
            shutil.copy(REPO / name, remote / name)
        for name in ("dots", "scripts"):
            shutil.copytree(REPO / name, remote / name)
        # Unrelated final hooks have their own coverage; don't download fonts,
        # install Flox, or generate keys in this repository-bootstrap test.
        for name in (
            "scripts/cli/flox_install.sh",
            "scripts/cli/nerdfonts_install.sh",
            "scripts/bootstrap/create_ssh_keys.sh",
        ):
            (remote / name).write_text("#!/bin/sh\nexit 0\n")
        self.run_command("git", "init", str(remote))
        self.run_command("git", "-C", str(remote), "add", ".")
        self.run_command(
            "git",
            "-C",
            str(remote),
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.com",
            "commit",
            "-m",
            "Fixture",
        )
        expected_tools = tomllib.loads(
            (REPO / "dots/.config/mise/config.toml").read_text()
        )["tools"]
        for profile in ("server", "workstation"):
            with self.subTest(profile=profile):
                base = self.root / profile
                home = base / "home"
                home.mkdir(parents=True)
                self.env.update(
                    HOME=str(home),
                    XDG_CONFIG_HOME=str(home / ".config"),
                    XDG_DATA_HOME=str(base / "data"),
                    XDG_CACHE_HOME=str(base / "cache"),
                    XDG_STATE_HOME=str(base / "state"),
                )
                checkout = base / "checkout with spaces"
                args = (
                    MISE,
                    "-E",
                    profile,
                    "bootstrap",
                    "--from",
                    str(remote),
                    "--from-dir",
                    str(checkout),
                )
                preview = self.run_command(*args, "--dry-run")
                self.assertFalse(checkout.exists())
                self.assertIn("clone", preview.lower())
                self.run_command(
                    MISE,
                    "vars",
                    "prompt",
                    "git_name=Test",
                    "git_email=test@example.com",
                )
                self.run_command(*args, "--only", "repos")
                config = home / ".config/mise/config.toml"
                self.assertFalse(config.exists())
                preview = self.run_command(*args, "--dry-run", "--skip", "tools")
                self.assertIn("create_ssh_keys.sh", preview)
                self.assertEqual(
                    "flatpak_install.sh" in preview, profile == "workstation"
                )
                self.assertFalse(config.exists())
                self.run_command(*args, "--only", "dotfiles")
                self.assertEqual(
                    config.resolve(), checkout / "dots/.config/mise/config.toml"
                )
                environment = (home / ".config/env.sh").read_text()
                self.assertIn(str(checkout), environment)
                self.assertIn(profile, environment)
                # Run the real final hook, replacing only its installer
                # subprocess with a tool-list probe to avoid downloads.
                fake_bin = base / "bin"
                fake_bin.mkdir()
                installer = fake_bin / "mise"
                installer.write_text(
                    "#!/bin/sh\nset -eu\n"
                    'test "$1" = -C\nshift 2\n'
                    'test "$1" = -E\nshift 2\n'
                    'test "$*" = "install --yes"\n'
                    'exec "$REAL_MISE" config --json > "$HOME/tools.json"\n'
                )
                installer.chmod(0o755)
                original_path = self.env["PATH"]
                self.env.update(
                    PATH=str(fake_bin) + ":" + original_path, REAL_MISE=MISE
                )
                self.run_command(*args, "--only", "final-hook")
                self.env["PATH"] = original_path
                tools = json.loads((home / "tools.json").read_text())
                self.assertIn(str(config), str(tools), tools)
                self.assertEqual(
                    tomllib.loads(config.read_text())["tools"], expected_tools
                )
                self.run_command(*args, "--only", "dotfiles")
                # --update must refresh the retained checkout from its remote.
                (remote / "revision").write_text(profile)
                self.run_command("git", "-C", str(remote), "add", "revision")
                self.run_command(
                    "git",
                    "-C",
                    str(remote),
                    "-c",
                    "user.name=Test",
                    "-c",
                    "user.email=test@example.com",
                    "commit",
                    "-m",
                    profile,
                )
                self.run_command(*args, "--update", "--only", "dotfiles")
                self.assertEqual((checkout / "revision").read_text(), profile)

    def test_migration_preserves_legacy_context_and_local_overrides(self):
        self.config.mkdir(parents=True)
        for name in ("config.server.toml", "config.workstation.toml"):
            (self.config / name).symlink_to(self.repo / "dots/.config/mise" / name)
        (self.config / "dotfiles").symlink_to(self.repo)
        context = self.config / "conf.d/00-dotfiles-context.toml"
        context.parent.mkdir()
        context.write_text(
            "# Generated by configure_mise.sh; rerun after moving the checkout.\n[vars]\n"
        )
        override = self.config / "config.server.local.toml"
        override.write_text("[tools]\n")
        self.configure()
        self.assertFalse(context.exists())
        self.assertFalse((self.config / "dotfiles").exists())
        self.assertEqual(override.read_text(), "[tools]\n")
        backup = next(self.config.glob(".dotfiles-backup.*"))
        self.assertTrue((backup / context.name).exists())
        self.configure()
        self.assertEqual(len(list(self.config.glob(".dotfiles-backup.*"))), 1)

    @unittest.skipUnless(MISE, "mise is required for config integration checks")
    def test_profiles_bootstrap_and_updates_from_outside_checkout(self):
        self.configure()
        (self.config / "config.local.toml").write_text(
            '[vars]\ngit_name="Test"\ngit_email="test@example.com"\n'
        )
        # Global defaults remain discoverable outside the checkout.
        configs = self.run_command(MISE, "config", "--json")
        self.assertIn("config.toml", configs)
        tools = tomllib.loads((self.config / "config.toml").read_text())["tools"]
        self.assertIn("herdr", tools)
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        flatpak = fake_bin / "flatpak"
        flatpak.write_text("#!/bin/sh\nexit 99\n")
        flatpak.chmod(0o755)
        original_path = self.env["PATH"]
        for profile in ("server", "workstation"):
            with self.subTest(profile=profile):
                self.env["PATH"] = original_path
                configs = self.run_command(
                    MISE, "-C", str(self.repo), "-E", profile, "config", "--json"
                )
                self.assertIn(f"mise.{profile}.toml", configs)
                other = "server" if profile == "workstation" else "workstation"
                self.assertNotIn(f"mise.{other}.toml", configs)
                # Skip version resolution/downloads; exercise all bootstrap path rendering.
                output = self.run_command(
                    MISE,
                    "-C",
                    str(self.repo),
                    "-E",
                    profile,
                    "bootstrap",
                    "--dry-run",
                    "--skip",
                    "tools",
                )
                self.assertNotIn("fedora_development_tools.sh", output)
                self.assertIn("create_ssh_keys.sh", output)
                self.assertIn("flox_install.sh", output)
                self.assertIn(
                    "flatpak_install.sh"
                    if profile == "workstation"
                    else "nerdfonts_install.sh",
                    output,
                )
                self.env["PATH"] = str(fake_bin) + ":" + original_path
                self.env.update(DOTFILES_REPO=str(self.repo), DOTFILES_PROFILE=profile)
                output = self.run_command(
                    "bash",
                    str(self.repo / "dots/.local/bin/system-update"),
                    "--dry-run",
                )
                self.assertIn(f"-E {profile} install --yes", output)
                self.assertIn(f"-E {profile} upgrade --yes", output)
                self.assertIn("bootstrap packages upgrade --yes", output)
                self.assertIn("flatpak update --user --assumeyes", output)
                self.assertIn("flatpak update --system --assumeyes", output)
                self.assertIn(
                    str(self.repo).replace(" ", r"\ ").replace(chr(34), r"\""), output
                )

    @unittest.skipUnless(MISE, "mise is required for dotfile integration checks")
    def test_home_group_deployment(self):
        self.configure()
        (self.config / "config.local.toml").write_text(
            '[vars]\ngit_name="Test"\ngit_email="test@example.com"\n'
        )
        self.run_command(MISE, "-C", str(self.repo), "-E", "server", "dot", "apply")
        for source in (REPO / "dots").rglob("*"):
            relative = source.relative_to(REPO / "dots")
            if not source.is_file():
                continue
            target = self.home / relative
            if source.suffix == ".tera":
                rendered = target.with_suffix("")
                self.assertTrue(rendered.is_file(), str(rendered))
                self.assertFalse(rendered.is_symlink())
                self.assertFalse(target.exists())
            else:
                self.assertTrue(target.is_symlink(), str(target))
                self.assertEqual(target.resolve(), source.resolve())
        self.assertIn("Test", (self.home / ".config/git/config").read_text())
        self.assertIn(str(self.repo), (self.home / ".config/env.sh").read_text())
        self.assertTrue((self.config / "config.toml").is_symlink())
        self.assertFalse((self.config / "config.local.toml").is_symlink())
        # Add a config after setup, using an isolated source tree.
        sources = self.root / "sources"
        shutil.copytree(REPO / "dots", sources)
        fragment = sources / ".config/mise/conf.d/extra.toml"
        fragment.parent.mkdir(parents=True)
        fragment.write_text('[vars]\ngroup_extra = "deployed"\n')
        local = self.config / "config.local.toml"
        project_local = self.repo / "mise.local.toml"
        project_local.write_text(
            "[settings.dotfiles]\nroot = " + json.dumps(str(sources)) + "\n"
        )
        local_config = local.read_text()
        self.run_command(MISE, "-C", str(self.repo), "-E", "server", "dot", "apply")
        deployed = self.config / "conf.d/extra.toml"
        self.assertTrue(deployed.is_symlink())
        self.assertEqual(deployed.resolve(), fragment)
        self.assertEqual((self.config / "config.local.toml").read_text(), local_config)
        self.assertIn("group_extra", self.run_command(MISE, "-E", "server", "vars"))

    def test_installer_links_configuration_before_bootstrap(self):
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        fake_mise = fake_bin / "mise"
        fake_mise.write_text("""#!/bin/sh
set -eu
config="$HOME/.config/mise"
test -L "$config/config.toml"
test ! -e "$config/conf.d/00-dotfiles-context.toml"
printf '%s\\n' "$*" >> "$HOME/mise-calls"
""")
        fake_mise.chmod(0o755)
        self.env["PATH"] = str(fake_bin) + ":" + self.env["PATH"]
        self.run_command("sh", str(self.repo / "install.sh"), "server")
        calls = (self.home / "mise-calls").read_text().splitlines()
        self.assertEqual(
            calls,
            [
                "trust",
                "-E server bootstrap --dry-run",
                "-E server bootstrap",
                "-E server bootstrap status",
            ],
        )
        # An explicit workstation profile overrides the noninteractive default.
        self.run_command("sh", str(self.repo / "install.sh"), "workstation")
        calls = (self.home / "mise-calls").read_text().splitlines()
        self.assertEqual(
            calls[-4:],
            [
                "trust",
                "-E workstation bootstrap --dry-run",
                "-E workstation bootstrap",
                "-E workstation bootstrap status",
            ],
        )
        # A standalone downloaded installer must work before logging helpers exist.
        downloaded = self.root / "downloaded-install.sh"
        shutil.copy(self.repo / "install.sh", downloaded)
        (self.repo / ".git").mkdir()
        self.env["DOTFILES_REPO_DIR"] = str(self.repo)
        self.run_command("sh", str(downloaded))
        calls = (self.home / "mise-calls").read_text().splitlines()
        self.assertEqual(
            calls[-4:],
            [
                "trust",
                "-E server bootstrap --dry-run",
                "-E server bootstrap",
                "-E server bootstrap status",
            ],
        )
        # Accept preparation, then decline bootstrap after its preview.
        master, slave = pty.openpty()
        try:
            os.write(master, b"y\nn\n")
            result = subprocess.run(
                ["sh", str(self.repo / "install.sh"), "server"],
                stdin=slave,
                env=self.env,
                cwd="/tmp",
                text=True,
                capture_output=True,
                timeout=10,
            )
        finally:
            os.close(slave)
            os.close(master)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = (self.home / "mise-calls").read_text().splitlines()
        self.assertEqual(
            calls[-3:],
            ["trust", "-E server vars prompt", "-E server bootstrap --dry-run"],
        )

    def test_declining_preparation_leaves_global_config_untouched(self):
        self.config.mkdir(parents=True)
        original = self.config / "config.toml"
        original.write_text("# existing config\n")
        master, slave = pty.openpty()
        try:
            os.write(master, b"n\n")
            result = subprocess.run(
                ["sh", str(self.repo / "install.sh"), "server"],
                stdin=slave,
                env=self.env,
                cwd="/tmp",
                text=True,
                capture_output=True,
                timeout=10,
            )
        finally:
            os.close(slave)
            os.close(master)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(
            "cancelled before global mise preparation", result.stdout + result.stderr
        )
        self.assertFalse(original.is_symlink())
        self.assertEqual(original.read_text(), "# existing config\n")
        self.assertEqual(list(self.config.iterdir()), [original])


if __name__ == "__main__":
    unittest.main()
