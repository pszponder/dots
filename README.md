# Dotfiles & Linux setup

Personal Linux workstation and server configuration, managed with [mise](https://mise.jdx.dev).

- Bootstrap packages, development tools, fonts, SSH keys, and dotfiles.
- Choose a workstation profile for your distribution or a server profile.
- Edit version-controlled dotfiles and deploy them through symlinks and templates.
- Keep machine-specific settings outside the repository.

[Installation](#installation) · [Usage](#usage) · [Updates](#updates) · [Documentation](#documentation)

## Prerequisites

| Requirement | Purpose |
| --- | --- |
| Linux with a supported profile | Workstation or server setup |
| Git and curl | Download the repository and install mise if needed |
| sudo access | System packages and workstation configuration where required |

The installer installs mise if needed. Bootstrap does not require host Python. Check the [distribution-specific requirements](docs/mise.md#packages-and-desktop-setup) before running setup.

## Installation

### Option 1: Install without cloning

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | sh
```

The installer reads input from your terminal, even when piped from curl. It guides you through:

1. Choosing a machine profile.
2. Confirming mise installation and global configuration preparation.
3. Entering missing setup values, including your Git author name and email.
4. Reviewing the bootstrap preview and confirming application.

Saved answers are reused on later runs. The repository is cloned into `~/repos/github/pszponder/dots` for the user running `sh`.

### Option 2: Use a local checkout

From the checkout root:

```sh
./install.sh                     # Choose a profile interactively
./install.sh workstation         # Detect the workstation distribution
./install.sh workstation-fedora  # Select a profile explicitly
```

The installer uses the current checkout directly.

### Profiles

| Machine | Profile |
| --- | --- |
| Ubuntu workstation | `workstation-ubuntu` |
| Debian workstation | `workstation-debian` |
| Fedora workstation | `workstation-fedora` |
| Arch workstation | `workstation-arch` |
| Universal Blue workstation | `workstation-ublue` |
| Server | `server` |

The installer shorthand `workstation` detects the distribution. Manual mise bootstrap commands require a full profile name, for example `mise -C bootstrap -E workstation-fedora bootstrap`.

### Unattended installation

Save `git_name` and `git_email` in `~/.config/mise/config.local.toml` first. Passing an explicit profile to the piped installer skips profile selection and applies setup without confirmation:

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | sh -s -- workstation
```

Noninteractive runs require an explicit profile. For unattended setup from a local terminal, use `./install.sh server --yes` with your chosen profile.

### Checkout location and forks

Set `DOTFILES_REPO_DIR` on the `sh` command to choose a different destination:

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | DOTFILES_REPO_DIR="$HOME/dotfiles" sh
```

Set `DOTFILES_REPO_URL` to clone a fork with the curl installer.

> **Keep the checkout in place after installation.** Deployed dotfiles are symlinks into it.

### Existing files and retries

Setup attempts normal deployment first, without scanning for conflicts or creating backups. If deployment fails, it shows the error and offers one force retry, defaulting to No. A failed force retry aborts setup. Global mise configuration linking follows the same approach.

Unattended force retries require explicit `--yes`, for example `./install.sh server --yes`. [Review replacements](docs/mise.md#confirm-replacements) before deploying over existing files.

### After installation

Open a new shell and run:

```sh
mise doctor
```

After successful setup, the installer switches a GitHub HTTPS `origin` to SSH. Add your SSH public key to GitHub before pulling or pushing. Other remote URLs are preserved. See [SSH configuration](docs/ssh_configuration.md).

## Usage

After installation, `mise dot` commands work from any directory without profile flags.

### Edit and apply dotfiles

Edit files under `dots/` or through their deployed symlinks. Paths mirror your home directory: `dots/.config/starship.toml` manages `~/.config/starship.toml`.

For generated files such as `env.sh` and Git configuration, edit the `.tera` source and apply it to render changes.

```sh
mise dot diff
mise dot apply --dry-run
mise dot apply
```

Applying deploys dotfiles and renders templates. Open a new shell after shell configuration changes, or reload the affected application. Use [full setup](#updates) for package and bootstrap changes.

### Add a dotfile

Preview, then capture an existing file:

```sh
mise dot add --group home --dry-run ~/.config/example/config.toml
mise dot add --group home ~/.config/example/config.toml
```

This moves the file into `dots/.config/example/config.toml` and replaces the original with a symlink. It applies immediately; add `--no-apply` to capture without applying. Review the captured file before committing.

You can also create files directly under their matching paths in `dots/`; the next apply includes them automatically. Use `mise run dotfiles:apply` for normal deployment with an optional force retry.

### Share changes across machines

Review `git diff`, then commit and push your changes. On another machine:

```sh
git pull --ff-only
mise dot diff
mise dot apply --dry-run
mise dot apply
```

See [editing and publishing dotfiles](docs/mise.md#edit-and-publish-dotfiles) for more options, including copy-managed files.

### Use dotfiles without full machine setup

With mise installed, run this once from the checkout, using your profile:

```sh
sh scripts/bootstrap/configure_mise.sh "$PWD" workstation-fedora
mise vars prompt
```

You can then use the `mise dot` commands above. `install.sh` already performs this preparation.

## Updates

| Task | Commands |
| --- | --- |
| Update the OS, tools, and packages | `up --dry-run`, then `up` from any directory |
| Pull and apply dotfile changes | `git pull --ff-only`, then review and run `mise dot apply` |
| Reapply full machine setup | Pull changes, then rerun `./install.sh <profile>` |

For example, from the checkout:

```sh
git pull --ff-only
./install.sh workstation-ubuntu
```

The installer applies the current checkout; it does not pull changes itself. Interactive runs confirm preparation and bootstrap separately. Noninteractive runs apply both stages automatically, with a separate `--yes` requirement for force retries.

Keep machine-local overrides in `~/.config/mise/config.local.toml`. Profile-specific overrides apply to bootstrap commands selecting that profile. See [updating tools and packages](docs/mise.md#update-tools-and-packages-from-any-directory) and [individual setup tasks](docs/mise.md#run-individual-setup-steps).

## Repository checks

Requires mise and Python 3.11+. Run from the checkout:

```sh
mise trust
mise run test   # Offline tests with temporary home directories
mise run lint   # TOML and shell syntax
mise run check  # Both; also run by CI
```

Install Zsh to check its startup-file syntax. Checks do not bootstrap the machine or run ShellCheck.

Full bootstrap installs Betterleaks globally through mise and enables this checkout's [pre-commit check](docs/security.md#betterleaks-pre-commit-check). For other clones, run `mise run hooks-install` to install Betterleaks and enable the hook. Existing custom hooks are preserved and need manual integration. Run `mise run secrets` to scan all locally available Git history.

## Security

Keep credentials, private keys, and machine-specific settings outside the checkout. Review files captured with `mise dot add` before committing. Before publishing the repository, scan its full Git history and review the personal information it exposes. See the [security recommendations](docs/security.md).

## Documentation

| Guide | Contents |
| --- | --- |
| [Setup and usage](docs/mise.md) | Configuration layout, packages, individual tasks, and customization |
| [Home directories](docs/directory_structure.md) | Directories created during bootstrap |
| [Git configuration](docs/git.md) | Identity, shared defaults, and local overrides |
| [SSH configuration](docs/ssh_configuration.md) | Keys and connections |
| [Tmux and Herdr bindings](docs/multiplexer-bindings.md) | Multiplexer shortcuts |
| [Security](docs/security.md) | Secret scanning and publishing precautions |
| [TODOs](docs/todo.md) | Planned work |
