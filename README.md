# Dotfiles with mise

Linux workstation and server dotfiles, deployed with [mise](https://mise.jdx.dev).

## Full machine setup

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

| Machine | Profile |
| --- | --- |
| Ubuntu workstation | `workstation-ubuntu` |
| Debian workstation | `workstation-debian` |
| Fedora workstation | `workstation-fedora` |
| Arch workstation | `workstation-arch` |
| Universal Blue workstation | `workstation-ublue` |
| Server | `server` |

Pass a profile to `./install.sh <profile>` or `mise -E <profile>`. The installer shorthand `workstation` detects the distribution; manual mise commands require a full profile name.

Keep the checkout: deployed symlinks point into it. The default is `~/repos/github/pszponder/dots`; override it with `DOTFILES_REPO_DIR` (or `DOTFILES_REPO_URL` for a fork). After setup, open a new shell and run `mise doctor`.

## Run individual setup steps

Requires Git, mise on `PATH`, and a trusted checkout:

```sh
git clone https://github.com/pszponder/dots.git "$HOME/repos/github/pszponder/dots"
cd "$HOME/repos/github/pszponder/dots"
mise trust
```

Run these commands from the checkout, replacing `workstation-ubuntu` with your profile from the table above.

### Bootstrap only: packages and directories

```sh
mise -E workstation-ubuntu bootstrap --only packages,files --dry-run
mise -E workstation-ubuntu bootstrap --only packages,files
```

Runs package hooks but skips dotfiles and final hooks. Use `--only packages` for packages alone. See [package notes](docs/mise.md#packages-and-desktop-setup) for platform requirements.

### Deploy dotfiles only

[Back up conflicting files](docs/mise.md#back-up-conflicts), then review and apply:

```sh
mise -E workstation-ubuntu vars prompt
mise -E workstation-ubuntu dot diff
mise -E workstation-ubuntu dot apply --dry-run
mise -E workstation-ubuntu dot apply
mise -E workstation-ubuntu dot status
```

Deploys files and runs dotfile hooks, including workstation wallpaper setup. Open a new shell afterward. Packages, tools, and CLI authentication are separate.

### Install global tools only

```sh
sh scripts/bootstrap/configure_mise.sh
mise -E workstation-ubuntu install --dry-run
mise -E workstation-ubuntu install
```

The helper links the [shared tool manifest](dots/.config/mise/config.toml), backs up conflicting global config, and preserves local overrides. `install` adds missing versions; use `upgrade` for updates. Shell startup files must [activate mise](https://mise.jdx.dev/getting-started.html) for tools to appear on `PATH`.

## Reapply full setup or update

From the checkout:

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation-ubuntu vars prompt
mise -E workstation-ubuntu bootstrap --dry-run
mise -E workstation-ubuntu bootstrap
mise -E workstation-ubuntu bootstrap status
```

Run `up --dry-run`, then `up` from any directory to [update the OS, tools, and packages](docs/mise.md#update-tools-and-packages-from-any-directory).

Keep machine-local overrides in `~/.config/mise/config.local.toml` or `config.<profile>.local.toml`.

## Repository checks

Requires mise and Python 3.11+:

```sh
mise trust
mise run test   # Offline tests with temporary home directories
mise run lint   # TOML and shell syntax
mise run check  # Both; also run by CI
```

Install Zsh to check its startup-file syntax. Checks do not bootstrap the machine or run ShellCheck.

## Documentation

- [Setup, customization, and daily usage](docs/mise.md)
- [Home directories](docs/directory_structure.md)
- [SSH configuration](docs/ssh_configuration.md)
- [Tmux and Herdr bindings](docs/multiplexer-bindings.md)
- [TODOs](docs/todo.md)
