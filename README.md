# Dotfiles with mise

Linux workstation and server dotfiles and bootstrap scripts, with explicit deployment through mise. This repository is independent of any desktop distribution.

See [mise setup and usage](docs/mise.md), [directory structure](docs/directory_structure.md), and [SSH configuration](docs/ssh_configuration.md).

## Install on a new machine

Run from a local checkout and choose the profile interactively:

```sh
./install.sh
```

Pass `workstation` or `server` to select a profile without the profile prompt:

```sh
./install.sh workstation
./install.sh server
```

To use a different clone location:

```sh
DOTFILES_REPO_DIR="$HOME/dotfiles" ./install.sh server
```

To use a different repository URL when the script needs to clone the repo:

```sh
DOTFILES_REPO_URL="https://github.com/yourname/dots.git" \
  DOTFILES_REPO_DIR="$HOME/dotfiles" ./install.sh workstation
```

To download and run the installer directly, without first cloning the repo:

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/dots/main/install.sh | sh
```

The installer installs mise with its official installer if needed. It clones the repository if needed, trusts its mise configuration, and previews the selected profile's bootstrap before asking whether to apply it. When no profile argument is provided, it prompts you to choose `workstation` or `server`. The default clone location is `~/repos/github/pszponder/dots`; set `DOTFILES_REPO_DIR` or `DOTFILES_REPO_URL` to override the clone location or repository URL.

## Run setup again

```sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
```

Use `server` instead of `workstation` on servers. Both profiles bootstrap directories, SSH keys, and Nerd Fonts. Workstation also installs Flatpak if missing and configures the per-user Flathub remote. Missing SSH keys prompt for passphrases. Review the dry run before applying.

## Update this machine

Run `up` to update the OS, Homebrew if installed, mise and the applied profile's tools and bootstrap packages, and Flatpak if installed. Use `up --dry-run` to preview commands. See [update behavior](docs/mise.md#update-tools-and-packages-from-any-directory).

## TODOs

- [ ] Configure Flatpak applications (through mise bootstrap)
- [ ] Install / setup [flox](https://flox.dev/docs/install-flox/install)
- [ ] Review [dotfile groups](https://mise.jdx.dev/dotfiles/groups.html), should we use them?

## Resources / References
- [mise](https://mise.jdx.dev)
