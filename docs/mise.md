# Setup and usage

Use the [README](../README.md) for installation and individual setup commands.

Available workstation profiles are `workstation-ubuntu`, `workstation-debian`, `workstation-fedora`, `workstation-arch`, and `workstation-ublue`; servers use `server`. Commands below use `-E workstation-ubuntu` as an example. Replace it with your machine's profile throughout. `./install.sh workstation` detects the distribution automatically; manual mise commands require the full profile name.

## Configuration layout

| File | Purpose |
| --- | --- |
| `mise.toml` | Shared directories, dotfiles, variables, and hooks |
| `mise.workstation-{ubuntu,debian,fedora,arch,ublue}.toml` | Complete distribution-specific desktop packages and hooks |
| `mise.server.toml` | Server profile |
| `dots/` | Sources mirroring home-directory paths |
| `dots/.config/mise/config.toml` | Global tools and tasks; projects can override them |
| `~/.config/mise/config.local.toml` | Machine-local overrides |

The home group links individual files under `dots/`, preserving unrelated files. Git configuration and `env.sh` are rendered from templates. New source files deploy automatically unless excluded.

The setup helper backs up conflicting global mise config, preserves local overrides, and retires legacy configuration links. `install.sh` confirms this preparation, then separately confirms bootstrap. Declining bootstrap leaves preparation in place; noninteractive runs apply both stages.

Bootstrap final hooks install global tools, Flox, SSH keys, and direct-download fonts where applicable, skipping existing matching installations. Universal Blue fonts are bootstrap packages instead. `dot apply` runs only dotfile hooks. Dry runs print final hooks without executing them; bootstrap status does not verify their installed state.

## Packages and desktop setup

Traditional workstation profiles and the server profile install development tools, Git, OpenSSH, and font-installation dependencies through apt, pacman, or dnf. Universal Blue relies on image-provided host prerequisites and declares no native packages. Mise runs every available declared package manager, so multiple declarations for an application can all apply. Package installation may request sudo; upgrades are explicit.

The workstation profiles add:

| Application | Ubuntu | Debian | Fedora | Arch |
| --- | --- | --- | --- | --- |
| Ghostty | Classic Snap | apt (repository required) | COPR/dnf | pacman |
| Visual Studio Code | Classic Snap | System Flatpak | System Flatpak | AUR |
| Obsidian | Classic Snap | System Flatpak | System Flatpak | pacman |
| Discord | Snap (Snapcrafters) | System Flatpak | System Flatpak | pacman |
| Zen | System Flatpak | System Flatpak | System Flatpak | AUR |
| Podman Desktop | User Flatpak | User Flatpak | User Flatpak | pacman |
| Helium | apt repository | apt repository | COPR/dnf | AUR |
| Brave Origin | Official installer | Official installer | Official installer | AUR |
| Yaak | Official Debian download | Official Debian download | Official RPM download | pacman |
| Zed | Official install script | Official install script | Official install script | pacman |
| Podman and Compose | apt | apt | dnf | pacman |

Ubuntu prefers project-published, project-endorsed, or Snapcrafters Snap packages, then Flatpak, then apt. Zed uses its official script on Ubuntu, Debian, and Fedora. Arch uses pacman packages where available and AUR packages otherwise, with no Flatpak setup or standalone app installers. Each application has one declared source; fallback choices are explicit, not retries after failed installations. The Ubuntu profile uses the existing Snap installation and expects snapd to be installed and running.

Sources checked for the Ubuntu Snap choices: [Ghostty's package documentation](https://ghostty.org/docs/install/binary), [VS Code](https://snapcraft.io/code), [Obsidian](https://snapcraft.io/obsidian), and [Discord](https://snapcraft.io/discord). The [Zen Snap](https://snapcraft.io/zen-browser-snap) has a different community publisher, so Zen uses Flatpak. No eligible Snap was found for Podman Desktop, Helium, Brave Origin, or Yaak; Brave's standard browser is a different application from Brave Origin.

`pre-packages` hooks only prepare system-wide Flatpak/Flathub on Ubuntu, Debian, and Fedora. `post-packages` hooks run the Zed, Brave Origin, and Yaak installers where applicable. On Ubuntu and Debian, the Helium post-packages hook configures its apt repository and installs `helium-bin`; Fedora and Arch retain declarative Helium packages. Existing native installations are preserved. Yaak's direct downloads remain pinned to 2026.9.0 and do not configure an update repository. Add system Flatpak apps as `"flatpak:APPLICATION_ID" = "latest"` in the appropriate workstation profile.

Requirements:

- Fedora development groups need mise with [PR #14347](https://github.com/jdx/mise/pull/14347); v2026.10.8 and earlier lack the fix.
- Ubuntu requires systemd and mise with native Snap support; mise v2026.10.9 cannot parse Snap options. Snap declarations need mise with [Snap support](https://github.com/jdx/mise/pull/14402) and working snapd.
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

CaskaydiaCove, CaskaydiaMono, and JetBrainsMono are installed by the download script outside Arch and the ublue workstation profile. Universal Blue installs the same families through declarative Linux font casks. The Arch workstation profile uses pacman packages `ttf-cascadia-code-nerd`, `ttf-cascadia-mono-nerd`, and `ttf-jetbrains-mono-nerd`, installed system-wide and updated through pacman. These packages are declared in `mise.workstation-arch.toml`. The download script skips Arch and its derivatives, so the server profile does not install Nerd Fonts on Arch.

On other Linux distributions, the script installs these families under `${XDG_DATA_HOME:-~/.local/share}/fonts/NerdFonts`; on macOS it uses `~/Library/Fonts/NerdFonts`. The script supports Linux and macOS, independently of the workstation profile.

For downloaded fonts, edit `dots/.config/nerd-fonts/fonts` for families and `nerdfonts_version` in `mise.toml` for the release. The installer skips matching versions and refreshes the font cache after changes. On Arch workstations, edit the `pacman:ttf-*-nerd` declarations in `mise.workstation-arch.toml`; pacman controls the installed version. Removing a declaration or family leaves installed fonts in place, including any previous downloaded copies. Select fonts in terminal applications separately.

### Universal Blue workstations

Use `./install.sh workstation-ublue`, or `./install.sh workstation` for detection on Bluefin, Bazzite, and Aurora. Declared `ublue` ancestry takes precedence over Fedora ancestry. Other custom images can select the profile explicitly.

The profile installs VS Code, Obsidian, Discord, Zen, Zed, and standard Brave as system Flatpaks, plus Podman Desktop as a user Flatpak. Standard Brave replaces the Brave Origin variant used by other profiles. Ghostty, Helium, and Yaak are omitted because no Flathub package was verified. No COPR, native GUI installers, external bundles, or host package layering are configured. Existing installations are preserved.

Flatpak must already be available from the image. The pre-packages hook configures both system and user Flathub remotes; it reports a missing Flatpak installation without attempting DNF. System remote configuration can request sudo.

Caskaydia Cove, Caskaydia Mono, and JetBrains Mono Nerd Fonts are declared as Linux `brew-cask:` bootstrap packages. Mise's cask backend downloads and installs them into the user font directory without requiring Homebrew. Fonts track current cask versions instead of `nerdfonts_version`; the direct font archive installer is skipped. Both full bootstrap and `bootstrap --only packages` include these fonts and the Flatpak apps. Cask metadata may require network access even for a dry run.

Global CLI tools remain in the shared mise manifest. Flox retains its immutable-host skip, and wallpaper configuration retains its existing desktop support.

Manual smoke check on Bluefin/Bazzite:

1. Review `mise -E workstation-ublue bootstrap --only packages --dry-run`, then apply without `--dry-run`.
2. Check `flatpak list --system` and `flatpak list --user`; launch the installed GUI apps from the desktop.
3. Check `fc-list | rg 'Caskaydia|JetBrainsMono'` and select a Nerd Font in a terminal.
4. Run `up --dry-run` after applying dotfiles and reloading the shell. Confirm an atomic OS upgrade, mise package upgrades, and both Flatpak scopes. A normal `up` must not run DNF or reboot automatically.

## Bootstrap from a repository

This repository is a mise bootstrap project: its entry point is root `mise.toml`, with `mise.workstation-<distribution>.toml` and `mise.server.toml` profiles. Use `--from`; `--adopt` expects either a global config repository or mise's dotfile-history format, neither of which matches this layout. See [mise repository bootstrap](https://mise.jdx.dev/bootstrap/from-repository.html).

With mise installed, run in a terminal:

```sh
mise -E workstation-ubuntu bootstrap \
  --from https://github.com/pszponder/dots.git \
  --from-dir "$HOME/repos/github/pszponder/dots" \
  --prompt-vars
```

Use your full workstation profile, or `server` throughout on servers. `--prompt-vars` collects missing Git identity values and saves them outside the checkout. For unattended setup, save them first, then run the command above with `--yes`:

```sh
mise vars prompt git_name="Your Name" git_email="you@example.com"
```

The first final hook loads the newly deployed global tool config in a fresh mise invocation, installing shared tools on the first bootstrap.

This direct path uses mise's dotfile conflict handling. It does not run the setup helper's config backup and legacy migration logic; use `install.sh` when you need those. mise still loads existing global configuration alongside this project. Keep the checkout at its selected location because deployed symlinks and `DOTFILES_REPO` refer to it. Without `--from-dir`, mise uses its data directory's `bootstrap-repo` checkout instead.

Add `--dry-run` to preview. When the checkout does not exist yet, that only prints the clone command. To clone and then preview the actual configuration before applying it:

```sh
git clone https://github.com/pszponder/dots.git "$HOME/repos/github/pszponder/dots"
mise -E workstation-ubuntu bootstrap \
  --from https://github.com/pszponder/dots.git \
  --from-dir "$HOME/repos/github/pszponder/dots" \
  --prompt-vars --dry-run
```

The preview prints the tool-install hook without installing tools. Required-variable prompting can still save answers during a dry run. Once reviewed, rerun without `--dry-run` to apply.

To pull and apply new commits later:

```sh
mise -E workstation-ubuntu bootstrap \
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

Both roles run `scripts/cli/flox_install.sh` during bootstrap, using the [official curl installer](https://flox.dev/docs/install-flox/install). Existing Flox installations are kept. Installation supports macOS, Debian/Ubuntu, and Fedora/RHEL-family systems on x86_64 and ARM64; unsupported systems (including Arch/Omarchy), immutable Linux systems, and existing Nix installations are skipped with a message. The installer may request sudo. Bootstrap dry runs only print the hook.

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
mise -E workstation-ubuntu vars prompt
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

## Migrating workstation profiles

The generic `mise.workstation.toml` has been replaced by complete distribution profiles. Run `./install.sh workstation` to detect and apply your distribution, or select one explicitly, such as `./install.sh workstation-fedora`. For dotfiles only, run `mise -E workstation-fedora dot apply`. Reload your shell afterward so `DOTFILES_PROFILE` and `MISE_ENV` contain the new full profile. Final hooks and `up` reuse that profile. Existing duplicate app installations are not uninstalled.

## Manual setup

Prefer [install.sh](../README.md#full-machine-setup) for a new machine. To prepare an existing checkout manually:

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation-ubuntu vars prompt
mise -E workstation-ubuntu bootstrap --dry-run
mise -E workstation-ubuntu bootstrap
mise -E workstation-ubuntu bootstrap status
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
mise -E workstation-ubuntu dot diff
mise -E workstation-ubuntu dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com

git diff
git add dots/ mise*.toml
git commit -m "Update dotfiles"
mise exec gh@latest -- git push
```

A symlinked source change is already visible through its live path. Reapply when changing mappings, copies, or templates.

You can also open a managed file’s source with:

```
mise -E workstation-ubuntu dot edit ~/.bashrc
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
mise -E workstation-ubuntu dot diff
mise -E workstation-ubuntu dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

Commit the source file and any group entry together.

## Capture application-written changes

For a file already managed in copy mode:

```
cd "$DOTFILES_REPO"

mise -E workstation-ubuntu dot diff
mise -E workstation-ubuntu dot add ~/.config/starship.toml
git diff
```

To capture all changed individual copy-managed files:

```
mise -E workstation-ubuntu dot add --changed
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
mise -E workstation-ubuntu dot apply --prompt-secrets
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

Prompted secrets remain in memory for that run. The rendered destination contains the secret, so keep that file out of source control and tracked-file history.

See [secret inputs](https://mise.jdx.dev/bootstrap/secrets.html).

## Remove a managed file

Removing a file from the group source tree leaves its deployed target in place as `orphaned`. Review with `mise -E workstation-ubuntu dot status`, then use `mise -E workstation-ubuntu dot apply --prune` to remove unchanged orphaned targets. Deleting an explicit mapping also leaves its target on disk.

To remove a previously deployed target locally, unapply it before deleting its mapping:

```
mise -E workstation-ubuntu dot unapply ~/.config/example/config.toml
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

The updater detects Linux using `/etc/os-release`, supporting Debian/Ubuntu (apt), Fedora/RHEL (dnf), Arch (pacman, or paru/yay when installed), openSUSE (zypper), and Alpine (apk). On Universal Blue and detected atomic hosts, it checks `bootc status --json`: bootc-managed deployments use `bootc upgrade`; other deployments use `rpm-ostree upgrade`. Missing atomic update support is reported as a failure. These hosts never use DNF. On macOS it runs `softwareupdate`. Homebrew is updated when installed, followed by its formulae and eligible casks. Arch AUR helpers retain their normal review prompts.

Mise installed by the OS or standard Homebrew installation is upgraded through that manager. Standalone mise installations use `mise self-update`. The updater then updates mise plugins, installs missing configured tools, upgrades configured tools within their version ranges, and upgrades installed `[bootstrap.packages]`. Shared global tools and the selected repository profile are included, so `latest` declarations receive new releases. Mise commands run from `DOTFILES_REPO` with the explicit server or distribution-specific workstation profile, including global tool configuration. It does not scan unrelated project configurations or upgrade unconfigured tool versions. See [tool upgrades](https://mise.jdx.dev/cli/upgrade.html) and [package upgrades](https://mise.jdx.dev/cli/bootstrap/packages/upgrade.html).

Flatpak updates both per-user and default system applications and runtimes when installed. Optional managers that are absent are skipped. Independent update steps continue after failures, with a final failure summary and nonzero exit status. OS and bootstrap updates may request sudo credentials. No automatic reboot is performed.

Mise updates use the recorded checkout and profile, including global tools. Override `DOTFILES_REPO` and `DOTFILES_PROFILE` explicitly for a single run if needed. See [moving the checkout](#move-the-checkout-or-change-profiles).
