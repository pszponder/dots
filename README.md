# Dotfiles with mise

Linux workstation and server dotfiles, deployed with [mise](https://mise.jdx.dev).

## Full machine setup

Use this for packages, directories, dotfiles, global mise tools, Flox, Nerd Fonts, and SSH key setup together. For individual steps, see [bootstrap only](#bootstrap-only-packages-and-directories), [dotfiles only](#deploy-dotfiles-only), or [global tools only](#install-global-tools-only).

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

## Run individual setup steps

These commands require Git, an installed `mise` on `PATH`, and a local checkout. Clone once if needed:

```sh
git clone https://github.com/pszponder/dots.git "$HOME/repos/github/pszponder/dots"
cd "$HOME/repos/github/pszponder/dots"
mise trust
```

Run the examples from the checkout. Replace `workstation` with `server` for a server. Keep the checkout in place because deployed symlinks point into it.

### Bootstrap only: packages and directories

Install the profile's system packages and create its declared directories:

```sh
mise -E workstation bootstrap --only packages,files --dry-run
mise -E workstation bootstrap --only packages,files
```

This selects `[bootstrap.packages]` and `[bootstrap.directories]` without deploying dotfiles or running the final hooks that install global tools, Flox, fonts, and SSH keys. Package hooks still run: workstation setup prepares Flatpak/Flathub, installs Zed and Brave Origin with their official Linux installers, and configures Helium's apt repository on Debian-family systems. Zen is installed from Flathub; Fedora uses Helium's COPR, while Arch installs the Brave Origin and Helium binary packages from the AUR. Ghostty is declared for Snap (`classic = true`), apt, Fedora's native `scottames/ghostty` COPR, and pacman. Mise skips unavailable managers and runs every available one; when both Snap and apt are available, both Ghostty declarations apply. Use a mise release with [Snap support](https://github.com/jdx/mise/pull/14402) and [native COPR support](https://mise.jdx.dev/bootstrap/packages/dnf.html#copr). Snap requires a working snapd installation; apt requires a repository providing `ghostty` (see [Ghostty packages](https://ghostty.org/docs/install/binary)). Package installation may request sudo. To select packages alone, use `--only packages`. See [mise bootstrap parts](https://mise.jdx.dev/bootstrap.html).

### Deploy dotfiles only

Collect the Git identity used by templates, review the deployment, then apply:

```sh
mise -E workstation vars prompt
mise -E workstation dot diff
mise -E workstation dot apply --dry-run
mise -E workstation dot apply
mise -E workstation dot status
```

Review and back up conflicting target files before applying; see [conflict handling](docs/mise.md#3-clone-and-review). This links files and renders templates, including the global mise tool configuration, but does not install packages or tools or run final bootstrap hooks. Dotfile hooks still run, including the workstation wallpaper configuration. Open a new shell afterward to load the managed environment and mise activation. CLI authentication remains a separate step.

### Install global tools only

Link the shared tool manifest into global mise configuration, preview downloads, then install missing tools:

```sh
sh scripts/bootstrap/configure_mise.sh
mise -E workstation install --dry-run
mise -E workstation install
```

The helper backs up conflicting global mise configuration, preserves local overrides, and retires legacy configuration links. It deploys the mise tool config without applying the rest of the dotfiles. Shared tools are declared in [`dots/.config/mise/config.toml`](dots/.config/mise/config.toml); machine-local declarations can also contribute tools. Running from this checkout avoids picking up another project's tool declarations.

`mise install` installs missing configured versions; use `mise -E workstation upgrade` to upgrade configured tools. These commands do not install bootstrap packages, Flox, or Nerd Fonts. If you have not deployed the shell startup files, configure [mise shell activation](https://mise.jdx.dev/getting-started.html) to put tools on `PATH`. See [mise install](https://mise.jdx.dev/cli/install.html).

## Reapply full setup or update

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
