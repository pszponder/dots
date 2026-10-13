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

In a terminal, the installer first asks permission to prepare global mise configuration. Preparation installs mise with its official installer if needed. It clones the repository if needed, trusts its mise configuration, and previews the selected profile's bootstrap before a separate confirmation to apply it. Declining bootstrap leaves the already-approved global mise preparation in place. When no profile argument is provided, it prompts you to choose `workstation` or `server` in a terminal, and defaults to `workstation` for noninteractive runs. Before previewing bootstrap, it links the global mise configs and records the checkout path; conflicting mise files are backed up. In a terminal, it runs `mise vars prompt` for the selected profile to collect missing configuration values before previewing. Noninteractive runs perform preparation and bootstrap without either confirmation. For unattended runs, first supply `git_name` and `git_email` in `~/.config/mise/config.local.toml` or save them with `mise vars prompt NAME=VALUE`; mise enforces required variables during setup. After bootstrap it reports status. Open a new shell and run `mise doctor` to verify activation. The default clone location is `~/repos/github/pszponder/dots`; set `DOTFILES_REPO_DIR` or `DOTFILES_REPO_URL` to override the clone location or repository URL.

## Run setup again

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
mise -E workstation bootstrap status
```

Use `server` instead of `workstation` on servers. Both profiles bootstrap directories, SSH keys, Nerd Fonts, Flox on supported systems, and globally available Codex and Claude Code CLIs. Servers also install Herdr. Global mise tool definitions live in `dots/.config/mise/` and are linked before bootstrap. Workstation also installs Flatpak if missing, configures the system-wide Flathub remote, and installs declared Flatpak apps, including Zed. Missing SSH keys prompt for passphrases. Review the dry run before applying.

## Update this machine

Run `up` to update the OS, Homebrew if installed, mise and the applied profile's tools and bootstrap packages, and Flatpak if installed. Use `up --dry-run` to preview commands. See [update behavior](docs/mise.md#update-tools-and-packages-from-any-directory).

## Repository checks

Keep machine declarations under `dots/.config/mise/`; root `mise.toml` provides checkout context and maintenance tasks. Initial machine setup uses `install.sh`.

With mise and Python 3.11 or newer available:

```sh
mise trust
mise run test   # Offline tests using temporary home directories
mise run lint   # TOML and shell syntax
mise run check  # Both
```

Install Zsh to include its startup-file syntax checks locally. CI installs Zsh and runs `mise run check` on pushes and pull requests. Checks do not bootstrap your machine. ShellCheck is not currently part of the check task.

Both profiles install Neovim (`nvim`) and bat through mise, plus `less` and `col` through the OS package manager, for the configured editor and pager. Other shell integrations activate when their executables are available; install those tools separately as needed.

Machine-local overrides belong in `~/.config/mise/config.local.toml` or `config.<profile>.local.toml`. Matching files under `dots/.config/mise/` are ignored by Git; keep personal overrides outside the deployed source tree.

## TODOs

- [ ] Configure Flatpak applications (through mise bootstrap)
- [ ] Add mise tools/packages
- [ ] Review my old dotfiles and import other configurations
- [ ] Configure desktop background?
- [ ] Install zed editor through the official installation script [Linux | Zed on Linux](https://zed.dev/docs/linux#standard-installation)
- [ ] Does mise support installing snaps (for Ubuntu?)
- [ ] Does mise support configuring copr installs (ex. [Binaries and Packages - Install](https://ghostty.org/docs/install/binary#fedora))
- [ ] Consider how can we [Bootstrap from a repository | mise-en-place](https://mise.jdx.dev/bootstrap/from-repository.html)
- [ ] Review [Bootstrap | mise-en-place](https://mise.jdx.dev/bootstrap.html) and [Set up a machine | mise-en-place](https://mise.jdx.dev/bootstrap/setup.html) for best practices and determine if we need to update our repo to follow those best practices
- [ ] Check out [Project scaffolding tasks | mise-en-place](https://mise.jdx.dev/mise-cookbook/presets.html) (I would want the scaffolding task to create a python project with pytest as a dev dependency, maybe don't create a bare project but an application ([Creating projects | uv](https://docs.astral.sh/uv/concepts/projects/init/)))
## Resources / References
- [mise](https://mise.jdx.dev)

## Script conventions

Executable shell scripts define their logic in functions and finish with `main "$@"`. Keep `main` focused on initialization and calling the workflow functions. Sourced helper libraries and shell startup configuration do not use a script entrypoint.
