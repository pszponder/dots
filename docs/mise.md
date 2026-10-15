# Setup and usage

Use the [README](../README.md) for installation and individual setup commands. Commands here run from the checkout with `-E workstation`; substitute `server` on servers.

## Configuration layout

| File | Purpose |
| --- | --- |
| `mise.toml` | Shared packages, directories, dotfiles, variables, and hooks |
| `mise.workstation.toml` | Desktop packages and wallpaper hook |
| `mise.server.toml` | Server profile |
| `dots/` | Sources mirroring home-directory paths |
| `dots/.config/mise/config.toml` | Global tools and tasks; projects can override them |
| `~/.config/mise/config.local.toml` | Machine-local overrides |

The home group links individual files under `dots/`, preserving unrelated files. Git configuration and `env.sh` are rendered from templates. New source files deploy automatically unless excluded.

The setup helper backs up conflicting global mise config, preserves local overrides, and retires legacy configuration links. `install.sh` confirms this preparation, then separately confirms bootstrap. Declining bootstrap leaves preparation in place; noninteractive runs apply both stages.

Bootstrap final hooks install global tools, Flox, SSH keys, and fonts on every run, skipping existing matching installations. `dot apply` runs only dotfile hooks. Dry runs print final hooks without executing them; bootstrap status does not verify their installed state.

## Packages and desktop setup

Both profiles install development tools, Git, OpenSSH, and font-installation dependencies through apt, pacman, or dnf. Mise runs every available declared package manager, so multiple declarations for an application can all apply. Package installation may request sudo; upgrades are explicit.

The workstation profile adds:

| Application | Installation |
| --- | --- |
| Zed | Official Linux installer |
| Brave Origin | Official installer; binary AUR package on Arch |
| Helium | apt repository, Fedora COPR, or binary AUR package |
| Zen | System Flatpak |
| Visual Studio Code | System Flatpak, classic Snap, or binary AUR package |
| Ghostty | Classic Snap, apt, pacman, or Fedora `scottames/ghostty` COPR |
| Yaak | Arch package; official 2026.9.0 Debian/RPM download on x64 or ARM64 |
| Podman | Native packages; Podman Desktop via user Flatpak |

Package hooks prepare system-wide Flatpak/Flathub and native installers. Existing native installations are preserved. Yaak's direct downloads do not configure an update repository; update those installations separately. Add system Flatpak apps as `"flatpak:APPLICATION_ID" = "latest"` in `mise.workstation.toml`.

Requirements:

- Fedora development groups need mise with [PR #14347](https://github.com/jdx/mise/pull/14347); v2026.10.8 and earlier lack the fix.
- Snap declarations need mise with [Snap support](https://github.com/jdx/mise/pull/14402) and working snapd.
- Fedora repositories need mise with [native COPR support](https://mise.jdx.dev/bootstrap/packages/dnf.html#copr).
- Ghostty on apt needs a [repository providing it](https://ghostty.org/docs/install/binary).

### Wallpaper

Workstation dotfile deployment sets `~/Pictures/wallpapers/catppuccin-mocha.png` on GNOME (light and dark), Omarchy, or COSMIC (all displays). Unsupported desktops and sessions without a display are skipped.

After installation over SSH or a console, run in a graphical terminal:

```sh
sh scripts/gui/configure_wallpaper.sh
```

GNOME and COSMIC require Python 3; GNOME also uses `gsettings`. COSMIC wallpaper files are backed up once with `.before-dotfiles`. Reapplying restores the repository wallpaper.

### Nerd Fonts

Both profiles install CaskaydiaCove, CaskaydiaMono, and JetBrainsMono under `${XDG_DATA_HOME:-~/.local/share}/fonts/NerdFonts`.

Edit `dots/.config/nerd-fonts/fonts` for families and `nerdfonts_version` in `mise.toml` for the release. The installer skips matching versions and refreshes the font cache after changes. Removing a family leaves installed files in place; select fonts in terminal applications separately.

## Bootstrap from a repository

This repository is a mise bootstrap project: its entry point is root `mise.toml`, with `mise.workstation.toml` and `mise.server.toml` profiles. Use `--from`; `--adopt` expects either a global config repository or mise's dotfile-history format, neither of which matches this layout. See [mise repository bootstrap](https://mise.jdx.dev/bootstrap/from-repository.html).

With mise installed, run in a terminal:

```sh
mise -E workstation bootstrap \
  --from https://github.com/pszponder/dots.git \
  --from-dir "$HOME/repos/github/pszponder/dots" \
  --prompt-vars
```

Use `server` instead of `workstation` throughout on servers. `--prompt-vars` collects missing Git identity values and saves them outside the checkout. For unattended setup, save them first, then run the command above with `--yes`:

```sh
mise vars prompt git_name="Your Name" git_email="you@example.com"
```

The first final hook loads the newly deployed global tool config in a fresh mise invocation, installing shared tools on the first bootstrap.

This direct path uses mise's dotfile conflict handling. It does not run the setup helper's config backup and legacy migration logic; use `install.sh` when you need those. mise still loads existing global configuration alongside this project. Keep the checkout at its selected location because deployed symlinks and `DOTFILES_REPO` refer to it. Without `--from-dir`, mise uses its data directory's `bootstrap-repo` checkout instead.

Add `--dry-run` to preview. When the checkout does not exist yet, that only prints the clone command. To clone and then preview the actual configuration before applying it:

```sh
git clone https://github.com/pszponder/dots.git "$HOME/repos/github/pszponder/dots"
mise -E workstation bootstrap \
  --from https://github.com/pszponder/dots.git \
  --from-dir "$HOME/repos/github/pszponder/dots" \
  --prompt-vars --dry-run
```

The preview prints the tool-install hook without installing tools. Required-variable prompting can still save answers during a dry run. Once reviewed, rerun without `--dry-run` to apply.

To pull and apply new commits later:

```sh
mise -E workstation bootstrap \
  --from https://github.com/pszponder/dots.git \
  --from-dir "$HOME/repos/github/pszponder/dots" \
  --update
```

Without `--update`, mise reuses the checkout's current commit. Updates require a fast-forward and matching origin. `--update` also refreshes bootstrap package metadata and configured repositories; use `up` for the broader machine and tool upgrades described below. Append `?ref=<branch|tag|commit>` to the repository URL to select a specific revision.

## Scaffold a Python application

After deploying dotfiles, the global `scaffold:python` task is available in any directory:

```sh
mkdir my-app
cd my-app
mise run scaffold:python
# Or select another Python version:
# mise run scaffold:python 3.13
# Or resolve and pin the latest available Python version:
# mise run scaffold:python latest
```

The task defaults to the latest available Python version, resolves it to a concrete version, and installs project-local Python and uv tool declarations. It runs `uv init --app --package` to create an application with a `src/` layout and command-line entry point, then adds pytest to the dev dependency group, creates `uv.lock`, and syncs `.venv`. It refuses to run if `pyproject.toml`, `mise.toml`, or `.mise.toml` already exists.

Add tests, then run `mise run test`. After cloning, run `mise run sync` to install locked dependencies. Both tasks use `--locked`; use `uv add` or `uv lock` when intentionally updating dependencies. Commit `mise.toml`, `pyproject.toml`, `uv.lock`, `.python-version`, and the generated application files. uv creates a `.gitignore` excluding `.venv` in a new Git repository; ensure `.venv/` is ignored when scaffolding inside an existing repository. pytest reports no tests until you add them.

See [mise scaffolding tasks](https://mise.jdx.dev/mise-cookbook/presets.html) and [uv application projects](https://docs.astral.sh/uv/concepts/projects/init/#applications).

## Flox

Both profiles run `scripts/cli/flox_install.sh` during bootstrap, using the [official curl installer](https://flox.dev/docs/install-flox/install). Existing Flox installations are kept. Installation supports macOS, Debian/Ubuntu, and Fedora/RHEL-family systems on x86_64 and ARM64; unsupported systems (including Arch/Omarchy), immutable Linux systems, and existing Nix installations are skipped with a message. The installer may request sudo. Bootstrap dry runs only print the hook.

After installation, initialize your user’s [default environment](https://flox.dev/docs/tutorials/default-environment) once:

```sh
flox auth login
flox init --default
flox install --default <package>
```

Managed Bash and Zsh startup files activate the default environment when Flox is installed. Authenticate and initialize it before opening a new shell. Authentication and default packages remain user-managed.

`up` upgrades default-environment packages from any directory. The OS package manager updates the Flox CLI on Debian/RPM installations; the bootstrap installer does not upgrade it.

## Choose deployment modes

| Mode           | Behavior                                       | Typical use                                                 |
| -------------- | ---------------------------------------------- | ----------------------------------------------------------- |
| `symlink`      | Links the live path to the repository source   | Files you edit yourself                                     |
| `symlink-each` | Creates directories and links individual files | Shared config directories where unrelated files must remain |
| `copy`         | Writes an independent copy                     | Applications that rewrite configuration                     |
| `template`     | Renders a template into a regular file         | Values that vary between machines                           |

Edits through a symlink usually change the repository source immediately. Copy and template changes require another apply.

Some applications replace symlinks when saving. Prefer copies for those files. Applications may need a reload or restart after configuration changes.

See [managed files](https://mise.jdx.dev/dotfiles/managed.html).

## Templates and personal values

For example, `dots/.config/git/config.tera`:

```
[user]
    name = {{ vars.git_name }}
    email = {{ vars.git_email }}

[init]
    defaultBranch = main
```

Collect personal values on each machine:

```
mise -E workstation vars prompt
```

Mise saves answers in `$MISE_STATE_DIR/vars.toml`, outside this repository. Subsequent commands reuse them.

To change an answer:

```
mise vars prompt git_email
```

If an answer is already saved, forget it first:

```
mise vars unset git_email
mise vars prompt git_email
```

Shared, non-sensitive defaults can be committed in `[vars]`. Machine-local overrides can go in `~/.config/mise/config.local.toml`:

```
[vars]
git_email = "work@example.com"
```

See [configuration variables](https://mise.jdx.dev/configuration/vars.html).

## Manual setup

Prefer [install.sh](../README.md#full-machine-setup) for a new machine. To prepare an existing checkout manually:

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
mise -E workstation bootstrap status
```

Open a new shell and run `mise doctor`. Earlier successful steps remain applied if a later step fails.

### Back up conflicts

Before applying, review the sources and back up existing target files. Move conflicting symlink targets out of the way; a backup copy alone leaves the conflict unresolved. After incorporating desired settings into `dots/.bashrc`, for example:

```sh
mv ~/.bashrc ~/.bashrc.bak
```

Choose an unused backup name and repeat for other conflicts, including `~/.config/nvim`. Back up copy and template targets too: applying overwrites their contents.

### Private repository authentication

For a private fork over HTTPS:

```sh
mise exec gh@latest -- gh auth login --hostname github.com --git-protocol https --web
mise exec gh@latest -- gh repo clone YOUR_USER/dotfiles ~/dotfiles
```

For remote sessions, complete browser authentication on your workstation. Run `mise exec gh@latest -- gh auth setup-git --hostname github.com` after deployment if it replaces your credential-helper configuration. Keep `gh` available for later Git operations. Existing SSH authentication also works; omit the HTTPS credential-helper commands below when using SSH.

## Edit and publish dotfiles

Edit the source files in the repository:

```
cd "$DOTFILES_REPO"

# Edit files, then review and apply:
mise -E workstation dot diff
mise -E workstation dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com

git diff
git add dots/ mise*.toml
git commit -m "Update dotfiles"
mise exec gh@latest -- git push
```

A symlinked source change is already visible through its live path. Reapply when changing mappings, copies, or templates.

You can also open a managed file’s source with:

```
mise -E workstation dot edit ~/.bashrc
```

## Update another machine

```
cd "$DOTFILES_REPO"
mise exec gh@latest -- git pull --ff-only

mise -E server dot diff
mise -E server dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

If package or other bootstrap declarations changed, run the full bootstrap instead:

```
mise -E server bootstrap --dry-run
mise -E server bootstrap
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

## Add a dotfile

Copy the existing file into its matching home-directory path under `dots/`; the home group deploys it automatically. For example, `dots/.config/example/config.toml` becomes `~/.config/example/config.toml`. To override the default linking behavior, add a group entry in `mise.toml`:

```
[dotfile_groups.home.entries]
"~/.config/example/config.toml" = { mode = "copy" }
```

Review and apply:

```
mise -E workstation dot diff
mise -E workstation dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

Commit the source file and any group entry together.

## Capture application-written changes

For a file already managed in copy mode:

```
cd "$DOTFILES_REPO"

mise -E workstation dot diff
mise -E workstation dot add ~/.config/starship.toml
git diff
```

To capture all changed individual copy-managed files:

```
mise -E workstation dot add --changed
```

Review, commit, and push afterward.

Capture copies before reapplying, or the repository version will overwrite the live edits. Capturing copies contents back; it is not a three-way merge.

Templates require manually incorporating changes into their source while preserving variables and conditions. See [capturing edits](https://mise.jdx.dev/dotfiles/managed.html#adopt-files-and-capture-edits).

## Handle credentials

Keep credentials out of committed variables and source files.

Declare a secret input in `mise.toml`:

```
[bootstrap.secrets]
api_token = "MY_API_TOKEN"

[dotfiles."~/.config/example/credentials"]
source = ".config/example/credentials.tera"
mode = "template"
permissions = "0600"
```

Reference it in the template:

```
{{ secret(name="api_token") }}
```

Supply the environment variable through your secret manager, or prompt during an attended run:

```
mise -E workstation dot apply --prompt-secrets
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

Prompted secrets remain in memory for that run. The rendered destination contains the secret, so keep that file out of source control and tracked-file history.

See [secret inputs](https://mise.jdx.dev/bootstrap/secrets.html).

## Remove a managed file

Removing a file from the group source tree leaves its deployed target in place as `orphaned`. Review with `mise -E workstation dot status`, then use `mise -E workstation dot apply --prune` to remove unchanged orphaned targets. Deleting an explicit mapping also leaves its target on disk.

To remove a previously deployed target locally, unapply it before deleting its mapping:

```
mise -E workstation dot unapply ~/.config/example/config.toml
```

To declare removal across machines, replace its mapping with:

```
[dotfiles]
"~/.config/example/config.toml" = { mode = "absent" }
```

The next apply removes that file.

## Move the checkout or change profiles

The rendered `~/.config/env.sh` records `DOTFILES_REPO` and `DOTFILES_PROFILE`; managed Bash and Zsh startup files load them and set `MISE_ENV`.

After moving the checkout, run `sh scripts/bootstrap/configure_mise.sh` from its new location. After moving it or changing profiles, reapply dotfiles with the selected profile and open a new shell.

## Update tools and packages from any directory

The `up` shell function runs `~/.local/bin/system-update` from any directory:

```sh
up --dry-run  # Print the update commands without executing them.
up
```

The updater detects Linux using `/etc/os-release`, supporting Debian/Ubuntu (apt), Fedora/RHEL (dnf), Arch (pacman, or paru/yay when installed), openSUSE (zypper), and Alpine (apk). On macOS it runs `softwareupdate`. Homebrew is updated when installed, followed by its formulae and eligible casks. Arch AUR helpers retain their normal review prompts.

Mise installed by the OS or standard Homebrew installation is upgraded through that manager. Standalone mise installations use `mise self-update`. The updater then updates mise plugins, installs missing configured tools, upgrades configured tools within their version ranges, and upgrades installed `[bootstrap.packages]`. Shared global tools and the selected repository profile are included, so `latest` declarations receive new releases. Mise commands run from `DOTFILES_REPO` with the explicit server or workstation profile, including global tool configuration. It does not scan unrelated project configurations or upgrade unconfigured tool versions. See [tool upgrades](https://mise.jdx.dev/cli/upgrade.html) and [package upgrades](https://mise.jdx.dev/cli/bootstrap/packages/upgrade.html).

Flatpak updates both per-user and default system applications and runtimes when installed. Optional managers that are absent are skipped. Independent update steps continue after failures, with a final failure summary and nonzero exit status. OS and bootstrap updates may request sudo credentials. No automatic reboot is performed.

Mise updates use the recorded checkout and profile, including global tools. Override `DOTFILES_REPO` and `DOTFILES_PROFILE` explicitly for a single run if needed. See [moving the checkout](#move-the-checkout-or-change-profiles).
