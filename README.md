# Dotfiles with mise

Linux workstation and server dotfiles, deployed with [mise](https://mise.jdx.dev).

## Install

From a local checkout:

```sh
./install.sh              # Choose a profile interactively
./install.sh workstation  # Or select workstation / server
```

Without cloning first:

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | sh
```

The installer prepares mise, collects missing configuration values, and previews bootstrap before applying it. Interactive runs ask for confirmation before preparation and application; noninteractive runs apply both and default to `server`. For unattended setup, supply `git_name` and `git_email` in `~/.config/mise/config.local.toml` first.

The default checkout is `~/repos/github/pszponder/dots`. Override it with `DOTFILES_REPO_DIR`, or set `DOTFILES_REPO_URL` to use another repository. Keep the checkout: deployed symlinks point into it. After setup, open a new shell and run `mise doctor`.

Already have mise? See [direct repository bootstrap](docs/mise.md#bootstrap-from-a-repository).

The workstation profile sets `~/Pictures/wallpapers/catppuccin-mocha.png` as
the wallpaper on GNOME (light and dark), Omarchy, or COSMIC (all displays).

It detects the running desktop and skips sessions without a display or an unsupported desktop. After installing from a console or SSH, run this from a terminal in your graphical session, in the checkout:

```sh
sh scripts/gui/configure_wallpaper.sh
```

GNOME and COSMIC configuration requires `python3`; GNOME also uses `gsettings`. COSMIC's existing wallpaper files are backed up once with a `.before-dotfiles`
suffix. Reapplying workstation bootstrap restores the repository wallpaper.

## Reapply or update

From the checkout, use `server` instead of `workstation` where appropriate:

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
mise -E workstation bootstrap status
```

Run `up` from any directory to update the OS, Homebrew, mise tools, bootstrap packages, and Flatpak where installed. Use `up --dry-run` to preview; see [update behavior](docs/mise.md#update-tools-and-packages-from-any-directory).

Keep machine-local overrides in `~/.config/mise/config.local.toml` or `config.<profile>.local.toml`, outside the deployed source tree.

## Repository checks

With mise and Python 3.11+ installed:

```sh
mise trust
mise run test   # Offline tests in temporary home directories
mise run lint   # TOML and shell syntax
mise run check  # Both; also run by CI
```

Install Zsh to include its startup-file syntax checks locally. Checks do not bootstrap your machine; ShellCheck is not included.

Bootstrap declarations live in `mise.toml` and `mise.<profile>.toml`; shared global tools live in `dots/.config/mise/config.toml`.

Executable shell scripts define functions and finish with `main "$@"`; keep `main` focused on initialization and workflow calls. Sourced libraries and shell startup files do not use an entrypoint.

## Documentation

- [mise setup and usage](docs/mise.md)
- [Directory structure](docs/directory_structure.md)
- [SSH configuration](docs/ssh_configuration.md)
- [TODOs](docs/todo.md)
