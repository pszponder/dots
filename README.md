# Bootstrap & Dotfiles with mise

Linux workstation and server bootstrap & dotfiles, deployed with [mise](https://mise.jdx.dev).

## Bootstrapping a New Machine

Requires Python 3.11+. The installer installs mise if needed.

From a local checkout:

```sh
./install.sh              # Choose workstation or server
./install.sh workstation  # Detect the workstation distribution
./install.sh workstation-fedora  # Select a profile explicitly
```

Without cloning first:

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | sh
```

Installs packages, directories, dotfiles, global tools, Flox where supported, Nerd Fonts, and SSH keys. Interactive runs confirm preparation and preview bootstrap before applying it. Noninteractive runs apply both stages and default to `server`; set `git_name` and `git_email` in `~/.config/mise/config.local.toml` first.

Available profiles:

| Machine                    | Profile              |
| -------------------------- | -------------------- |
| Ubuntu workstation         | `workstation-ubuntu` |
| Debian workstation         | `workstation-debian` |
| Fedora workstation         | `workstation-fedora` |
| Arch workstation           | `workstation-arch`   |
| Universal Blue workstation | `workstation-ublue`  |
| Server                     | `server`             |

Pass a profile to `./install.sh <profile>` or `mise -C bootstrap -E <profile>`. The installer shorthand `workstation` detects the distribution; manual bootstrap commands require a full profile name.

Keep the checkout: deployed symlinks point into it. The default is `~/repos/github/pszponder/dots`; override it with `DOTFILES_REPO_DIR` (or `DOTFILES_REPO_URL` for a fork). After setup, open a new shell and run `mise doctor`.

## Managing Dotfiles

If you skipped full machine setup, prepare global configuration once from the checkout with mise and Python 3.11+ installed:

```sh
sh scripts/bootstrap/configure_mise.sh "$PWD" workstation-fedora  # Use your profile
mise vars prompt
```

`install.sh` already performs this preparation. After preparation, the `mise dot` commands below work from any directory without profile flags.

### Editing Dotfiles

Edit files under `dots/` or through their deployed symlinks; both change the same file. Paths mirror your home directory: `dots/.config/starship.toml` manages `~/.config/starship.toml`. Edit `.tera` sources for generated files, such as `env.sh` and Git configuration, then run `mise dot apply` to render changes.

### Adding Dotfiles

```sh
mise dot add --group home --dry-run ~/.config/example/config.toml
mise dot add --group home ~/.config/example/config.toml
```

This captures the file into `dots/.config/example/config.toml` and replaces the original home-directory file with a symlink to it. It applies the new file immediately; use `--no-apply` to capture without applying. Review and commit the captured file. Future edits through either path change the same file.

You can also create new files directly under their matching paths in `dots/`; they are included automatically on the next apply. Keep secrets and machine-specific values outside the repository. [Back up conflicting files](docs/mise.md#back-up-conflicts) before deploying repository files over existing home-directory files.

### Applying Dotfiles to the System

```sh
mise dot diff
mise dot apply --dry-run
mise dot apply
```

Applying deploys files and renders templates. It does not install packages or tools or run full bootstrap. Open a new shell for shell configuration changes, or reload/restart the affected application. Package or bootstrap changes require the full setup below.

Review `git diff`, then commit and push the files you changed to share them with other machines. On another machine, run `git pull --ff-only`, then the review/apply commands above. See [editing and publishing dotfiles](docs/mise.md#edit-and-publish-dotfiles) for more options, including capturing changes to copy-managed files.

## Reapply full setup or update

From the checkout, pull repository changes if needed, then rerun the installer with your profile:

```sh
git pull --ff-only
./install.sh workstation-ubuntu  # Or server, workstation-fedora, etc.
```

The installer prepares global mise configuration, trusts the checkout, prompts for missing variables, previews bootstrap, and applies it after confirmation. Noninteractive runs apply both preparation and bootstrap automatically. It applies the current checkout without pulling repository changes itself.

Run `up --dry-run`, then `up` from any directory to [update the OS, tools, and packages](docs/mise.md#update-tools-and-packages-from-any-directory).

Keep machine-local overrides in `~/.config/mise/config.local.toml`. Profile-specific overrides apply to bootstrap commands that select that profile.

## Security and publishing

Keep credentials, private keys, and machine-specific settings outside the checkout. Review files captured with `mise dot add` before committing them. Before making this repository public, scan its full Git history and review the personal information it exposes. See [security recommendations](docs/security.md) for the publishing checklist and ongoing precautions.

## Repository checks

Requires mise and Python 3.11+:

```sh
mise trust
mise run test   # Offline tests with temporary home directories
mise run lint   # TOML and shell syntax
mise run check  # Both; also run by CI
```

Full bootstrap installs Betterleaks globally through mise and enables this checkout's [pre-commit check](docs/security.md#betterleaks-pre-commit-check). For other clones, run `mise run hooks-install` to install Betterleaks and enable the hook. Existing custom hooks are preserved and need manual integration. Run `mise run secrets` to scan all locally available Git history.

Install Zsh to check its startup-file syntax. Checks do not bootstrap the machine or run ShellCheck.

## Documentation

- [Setup, customization, and daily usage](docs/mise.md)
- [Home directories](docs/directory_structure.md)
- [SSH configuration](docs/ssh_configuration.md)
- [Tmux and Herdr bindings](docs/multiplexer-bindings.md)
- [TODOs](docs/todo.md)
