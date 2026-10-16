# Bootstrap & Dotfiles with mise

Linux workstation and server bootstrap & dotfiles, deployed with [mise](https://mise.jdx.dev).

## Bootstrapping a New Machine

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

Pass a profile to `./install.sh <profile>` or `mise -C bootstrap -E <profile>`. The installer shorthand `workstation` detects the distribution; manual mise commands require a full profile name.

Keep the checkout: deployed symlinks point into it. The default is `~/repos/github/pszponder/dots`; override it with `DOTFILES_REPO_DIR` (or `DOTFILES_REPO_URL` for a fork). After setup, open a new shell and run `mise doctor`.

## Run individual setup steps

Requires Git, Python 3.11+, mise on `PATH`, and a trusted checkout:

```sh
git clone https://github.com/pszponder/dots.git "$HOME/repos/github/pszponder/dots"
cd "$HOME/repos/github/pszponder/dots"
mise -C bootstrap trust
```

Run preparation and bootstrap commands from the checkout, replacing `workstation-ubuntu` with your profile from the table above. After preparation, `mise dot` and global tool commands work from any directory.

### Bootstrap only: packages and directories

```sh
mise -C bootstrap -E workstation-ubuntu bootstrap --only packages,files --dry-run
mise -C bootstrap -E workstation-ubuntu bootstrap --only packages,files
```

Runs package hooks but skips dotfiles and final hooks. Use `--only packages` for packages alone. See [package notes](docs/mise.md#packages-and-desktop-setup) for platform requirements.

### Deploy dotfiles only

Prepare global configuration once from the checkout (also done by `install.sh`):

```sh
sh scripts/bootstrap/configure_mise.sh "$PWD" workstation-ubuntu
```

Use your machine profile for preparation. Then run the following commands from any directory, without profile flags. The same dotfiles deploy on servers and workstations.

[Back up conflicting files](docs/mise.md#back-up-conflicts), then review and apply:

```
mise vars prompt
mise dot diff
mise dot apply --dry-run
mise dot apply
mise dot status
```

Deploys files and runs dotfile hooks, including workstation wallpaper setup. Open a new shell afterward. Packages, tools, and CLI authentication are separate.

### Install global tools only

```sh
sh scripts/bootstrap/configure_mise.sh
mise install --dry-run
mise install
```

The helper saves the checkout path and profile in `~/.config/mise/conf.d/01-dotfiles-machine.toml` and links the [shared global manifest](dots/.config/mise/config.toml), backs up conflicting global config, and preserves local overrides. `install` adds missing versions; use `upgrade` for updates. Shell startup files must [activate mise](https://mise.jdx.dev/getting-started.html) for tools to appear on `PATH`.

## Managing Dotfiles

Edit the source files under `dots/` in this checkout. Paths mirror your home directory: `dots/.bashrc` manages `~/.bashrc`, and `dots/.config/starship.toml` manages `~/.config/starship.toml`. Most deployed files are symlinks, so source edits are immediately visible at their home-directory paths. Edit `.tera` source files for generated configuration, such as Git identity and `env.sh`; reapply to render changes.

After the one-time preparation above, import an existing file from any directory with `mise dot add`:

```sh
mise dot add --group home --dry-run ~/.config/example/config.toml
mise dot add --group home ~/.config/example/config.toml
```

This captures the file into `dots/.config/example/config.toml` and replaces the original home-directory file with a symlink to it. It applies the new file immediately; use `--no-apply` to capture without applying. Review and commit the captured file. Future edits through either path change the same file.

You can also create new files directly under their matching paths in `dots/`; they are included automatically on the next apply. Keep secrets and machine-specific values outside the repository. [Back up conflicting files](docs/mise.md#back-up-conflicts) before deploying repository files over existing home-directory files.

After the one-time preparation above, review and apply your changes from any directory:

```sh
mise dot diff
mise dot apply --dry-run
mise dot apply
```

Applying deploys new files, rerenders templates, and runs dotfile hooks. Open a new shell for shell configuration changes, or reload/restart the affected application. Package or bootstrap changes require the full setup below.

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
