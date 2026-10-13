# Dotfiles with mise

Manage Linux dotfiles and bootstrap workstation/server environments from a private Git repository.

This repository uses explicit deployment: edit source files, review changes, and apply them. Automatic history synchronization is optional and is not enabled here.

## Current bootstrap configuration

The installer asks for confirmation before preparing global mise configuration, then previews bootstrap and asks separately before applying it. Declining the second prompt leaves preparation in place. Noninteractive runs apply both stages without confirmation and default to `server` unless a profile is supplied. Directly running `configure_mise.sh` applies preparation immediately. See [repository checks](../README.md#repository-checks) for maintenance tasks.

Dotfile sources live under `dots/` and mirror their home-directory paths. The active configuration deploys the portable Bash and Zsh startup files, shared aliases and environment, Git defaults, Starship, tmux, Nerd Fonts selection, and the SSH key helper. The `home` group in `mise.toml` links each file under `dots/` into its matching home-directory path. Group entries render `env.sh.tera` and Git’s `config.tera` to their destinations instead of linking the template sources. The setup helper links the shared global tool config before bootstrap; the home group also manages this link and deploys additional files under `dots/.config/mise/` on subsequent applies. Machine-local overrides remain untouched. New files under `dots/` are deployed automatically unless excluded.

From the repository, select one profile:

```sh
sh scripts/bootstrap/configure_mise.sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
# On servers, replace workstation with server.
```

Both profiles install OpenSSH using apt, pacman, or dnf, create the directories in `[bootstrap.directories]`, deploy the helper/environment files, and run the final SSH key hook. Run in a terminal: missing keys prompt for passphrases. Existing keys remain untouched. See [SSH setup](ssh_configuration.md) and [directory structure](directory_structure.md).

Both profiles declare the Fedora `@development-tools` group in shared `[bootstrap.packages]`. This requires a mise release containing [PR #14347](https://github.com/jdx/mise/pull/14347); v2026.10.8 and earlier do not include the fix. The workstation profile's `pre-packages` hook runs `scripts/gui/flatpak_install.sh` to install the Flatpak CLI through apt, dnf, or pacman if missing, then add the system-wide Flathub remote with `flatpak remote-add --system --if-not-exists`, using sudo unless running as root. Existing remotes are preserved. Mise then installs the applications declared under `[bootstrap.packages]`, including Zed. Add more apps to `mise.workstation.toml` as `"flatpak:APPLICATION_ID" = "latest"` to match the hook's system scope. The server profile does not install Flatpak. The workstation also declares Ghostty for apt (Ubuntu 26.04 or newer), pacman, and dnf. Its `scripts/bootstrap/setup_copr.sh` pre-packages hook enables `scottames/ghostty` COPR only on Fedora before mise installs packages. Older Ubuntu releases are unsupported by the Ghostty apt declaration. The server profile does not install Ghostty. See [mise Flatpak packages](https://mise.jdx.dev/bootstrap/packages/flatpak.html).

Both profiles install curl, tar, XZ support, fontconfig, Git, and OpenSSH through the supported system package manager, then install CaskaydiaCove, CaskaydiaMono, and JetBrainsMono under `~/.local/share/fonts/NerdFonts` (or `$XDG_DATA_HOME/fonts/NerdFonts`). Fedora declares `openssh-clients`, `xz`, `fontconfig`, and `tar` for SSH and font installation.

Edit `dots/.config/nerd-fonts/fonts` to select font families and `nerdfonts_version` in `mise.toml` to select a release. The installer downloads official [Nerd Fonts release archives](https://github.com/ryanoasis/nerd-fonts/releases), records each installed version, skips matching installed families, and refreshes the font cache after changes. Removing a family from the manifest leaves its installed files in place. Font selection in terminal applications is configured separately.

Bootstrap final hooks run on every bootstrap, including when keys and fonts already exist. `dot apply` deploys sources but does not run these final hooks. Bootstrap status describes declarative resources, but does not verify SSH key or font installer state. A dry run prints the final hooks without generating keys or downloading fonts. See [mise bootstrap run order](https://mise.jdx.dev/bootstrap.html#run-order).

The rendered `~/.config/env.sh` contains the repository location, selected profile, and shared shell environment. Managed Bash and Zsh startup files load it directly. After moving the repository, rerun `sh scripts/bootstrap/configure_mise.sh` from the new checkout, reapply from that checkout, and reload your shell.

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

The home dotfile group deploys `~/.config/mise/config.toml`. The first final hook starts a fresh `mise install` invocation with the checkout and profile explicitly selected, so it loads that newly deployed config and installs the shared tools on the first bootstrap. The tool manifest remains solely in `dots/.config/mise/config.toml`. On later runs, already-installed matching tools are kept. Other final hooks then install Flox and fonts and prepare SSH keys.

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

## Flox

Both profiles run `scripts/cli/flox_install.sh` during bootstrap, using the [official curl installer](https://flox.dev/docs/install-flox/install). Existing Flox installations are kept. Installation supports macOS, Debian/Ubuntu, and Fedora/RHEL-family systems on x86_64 and ARM64; unsupported systems (including Arch/Omarchy), immutable Linux systems, and existing Nix installations are skipped with a message. The installer may request sudo. Bootstrap dry runs only print the hook.

After installation, initialize your user’s [default environment](https://flox.dev/docs/tutorials/default-environment) once:

```sh
flox auth login
flox init --default
flox install --default <package>
```

Following Flox’s official shell setup, `.bashrc` and `.profile` (Bash), and `.zshrc` and `.zprofile` (Zsh), end with `eval "$(flox activate -D -m run)"`, guarded by a check that Flox is installed. The managed `.bash_profile` sources `.bashrc` and `.profile`, since Bash otherwise skips `.profile` when `.bash_profile` exists. Authenticate and initialize the environment before opening a new shell. Authentication and default packages are user-managed, outside these dotfiles.

When Flox is on PATH, `up` runs `flox upgrade --default` to upgrade all default-environment packages, regardless of the current project directory. `up --dry-run` prints this command without running Flox. Failures appear in the updater’s final failure summary. The Flox CLI itself is updated by the OS package manager on Debian/RPM installations; the bootstrap installer does not upgrade it.

## Example expanded repository layout

```
dots-repo/
├── install.sh
├── mise.toml
├── mise.workstation.toml
├── mise.server.toml
├── scripts/
├── tests/
└── dots/
    ├── .bashrc
    ├── .zshenv
    └── .config/
        ├── env.sh.tera
        └── mise/
            └── config.toml
```

Root `mise.toml` sets `settings.dotfiles.root = "dots"`, relative to the checkout. The home group uses `root = "."`, relative to that setting. Hooks use `vars.dotfiles_repo`, derived from `config_root`.

## Configure the repository

Put shared configuration in `mise.toml`:

```
[vars]

[vars.git_name]
required = "Set your Git author name"
prompt = "Git author name"

[vars.git_email]
required = "Set your Git email"
prompt = "Git email"

[dotfile_groups.home]
root = "."
target = "~"
mode = "symlink-each"

[dotfile_groups.home.entries]
"~/.config/env.sh" = { source = ".config/env.sh.tera", mode = "template" }
"~/.config/git/config" = { source = ".config/git/config.tera", mode = "template" }

[bootstrap.packages]
"apt:git" = "latest"
"apt:curl" = "latest"
"apt:ripgrep" = "latest"
"apt:neovim" = "latest"

"pacman:git" = "latest"
"pacman:curl" = "latest"
"pacman:ripgrep" = "latest"
"pacman:neovim" = "latest"
```

Create the source files before applying. For an existing configuration, copy the desired files into the repository and review them before committing.

Mise skips packages whose package manager is unavailable. A `"latest"` package declaration installs a missing package but accepts the version already installed. Upgrades are explicit. See [bootstrap packages](https://mise.jdx.dev/bootstrap/packages/).

Add workstation configuration in `mise.workstation.toml`:

```
[vars]
dotfiles_profile = "workstation"

[dotfiles]
"~/.config/kitty/kitty.conf" = {
  source = ".config/kitty/kitty.conf",
  mode = "symlink"
}

[bootstrap.packages]
"apt:kitty" = "latest"
"pacman:kitty" = "latest"
```

Add server configuration in `mise.server.toml`:

```
[vars]
dotfiles_profile = "server"

[bootstrap.packages]
"apt:tmux" = "latest"
"pacman:tmux" = "latest"
```

Select a profile with `-E workstation` or `-E server`. The profile adds to the shared configuration. Use the same profile for subsequent commands. See [configuration environments](https://mise.jdx.dev/configuration/environments.html).

Add these exclusions to `.gitignore`:

```
mise.local.toml
mise.*.local.toml
/dots/.config/mise/config.local.toml
/dots/.config/mise/config.*.local.toml
.env
.env.*
```

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

## Set up a new machine

### 1. Install prerequisites

On Debian or Ubuntu:

```
sudo apt-get update
sudo apt-get install -y git curl
```

On Arch:

```
sudo pacman -Syu --needed git curl
```

Install mise:

```
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
```

### 2. Authenticate with GitHub

For a private repository using HTTPS:

```
mise exec gh@latest -- gh auth login \
  --hostname github.com --git-protocol https --web
```

When connected over SSH, open the displayed login URL in your workstation’s browser and enter the provided code. The server receives the authorization.

The clone below uses `gh` directly. After bootstrap, configure Git to use `gh` as a credential helper, and keep it available whenever fetching or pushing. These instructions run Git commands through `mise exec gh@latest` for that reason.

Existing working SSH authentication is also suitable. See [repository authentication](https://mise.jdx.dev/dotfiles/sync.html#repository-authentication).

### 3. Clone and review

Replace `YOUR_USER` with your GitHub username:

```
mise exec gh@latest -- gh repo clone \
  https://github.com/YOUR_USER/dotfiles.git ~/path/to/dotfiles

cd ~/path/to/dotfiles
```

Review the configuration and sources, then trust the repo:

```
sh scripts/bootstrap/configure_mise.sh
mise trust
```

Before the first apply, review and back up existing target files. For symlink mappings, move conflicting files or directories out of the way; copying a backup alone leaves the conflict unresolved. For example, after copying any settings you want into `dots/.bashrc`:

```
mv ~/.bashrc ~/.bashrc.bak
```

Choose an unused backup name. Repeat for other conflicting symlink targets, including `~/.config/nvim`. Copy and template mappings overwrite existing target contents, so back those up too.

### 4. Bootstrap

For a workstation:

```
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
mise exec gh@latest -- gh auth setup-git --hostname github.com
mise -E workstation bootstrap status
```

For a server:

```
mise -E server vars prompt
mise -E server bootstrap --dry-run
mise -E server bootstrap
mise exec gh@latest -- gh auth setup-git --hostname github.com
mise -E server bootstrap status
```

Open a new shell after bootstrap and run `mise doctor` to verify shell activation.

Bootstrap applies the declared setup, including packages and dotfiles. Run it again after changing bootstrap declarations. Earlier successful steps remain applied if a later step fails.

For HTTPS authentication, run `gh auth setup-git` after every apply or bootstrap that deploys `~/.gitconfig`: the template replaces the credential helpers configured by that command. The examples below include this repair. With SSH authentication, omit the `gh auth setup-git` commands.

See [mise bootstrap](https://mise.jdx.dev/bootstrap.html).

## Edit and publish dotfiles

Edit the source files in the repository:

```
cd ~/dotfiles

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
cd ~/dotfiles
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
cd ~/dotfiles

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

## Tool versions and shell activation

Bootstrap packages, directories, dotfile mappings, hooks, and setup variables live in root `mise.toml`. `mise.workstation.toml` adds Flatpak setup; `mise.server.toml` selects the server profile. Run bootstrap and dotfile commands from the checkout, or pass `mise -C "$DOTFILES_REPO" -E "$DOTFILES_PROFILE" ...`.

Shared `[tools]` declarations live in `dots/.config/mise/config.toml`, linked into global mise configuration. Both profiles install bat, Neovim, Codex, Claude Code, and Herdr. These are user-wide defaults that project configuration can override.

Run `sh scripts/bootstrap/configure_mise.sh` once before direct bootstrap, or use `install.sh`, which runs it automatically. The helper links global tools before bootstrap so the first run installs them. Conflicting global config is backed up and local overrides are preserved. When migrating from the previous layout, legacy profile links, the checkout link, and generated context are moved into a backup directory. Root configuration now supplies checkout context.

After moving the checkout, rerun the helper, apply dotfiles from the new checkout with the selected profile, and reload your shell. `dot apply` only deploys files; run `mise install` to install newly declared global tools without a full bootstrap. Tool installation does not configure CLI authentication.

Configure [mise shell activation](https://mise.jdx.dev/getting-started.html) in your managed shell startup file when using mise-installed tools interactively.

## Update tools and packages from any directory

Root `mise.toml` derives the repository path from `config_root`. Each root profile sets `dotfiles_profile`. The managed `dots/.config/env.sh.tera` includes these exports alongside the shared shell environment:

```jinja
export DOTFILES_REPO={{ vars.dotfiles_repo | quote }}
export DOTFILES_PROFILE={{ vars.dotfiles_profile | quote }}
```

The `quote` filter formats values safely for Bash, including paths containing spaces. See [mise templates](https://mise.jdx.dev/templates.html).

The managed Bash and Zsh startup files source `~/.config/env.sh`. `MISE_ENV` follows the applied `DOTFILES_PROFILE`. The `up` function calls the managed `~/.local/bin/system-update` script, which works from any directory:

```sh
up --dry-run  # Print the update commands without executing them.
up
```

The updater detects Linux using `/etc/os-release`, supporting Debian/Ubuntu (apt), Fedora/RHEL (dnf), Arch (pacman, or paru/yay when installed), openSUSE (zypper), and Alpine (apk). On macOS it runs `softwareupdate`. Homebrew is updated when installed, followed by its formulae and eligible casks. Arch AUR helpers retain their normal review prompts.

Mise installed by the OS or standard Homebrew installation is upgraded through that manager. Standalone mise installations use `mise self-update`. The updater then updates mise plugins, installs missing configured tools, upgrades configured tools within their version ranges, and upgrades installed `[bootstrap.packages]`. Shared global tools and the selected repository profile are included, so `latest` declarations receive new releases. Mise commands run from `DOTFILES_REPO` with the explicit server or workstation profile, including global tool configuration. It does not scan unrelated project configurations or upgrade unconfigured tool versions. See [tool upgrades](https://mise.jdx.dev/cli/upgrade.html) and [package upgrades](https://mise.jdx.dev/cli/bootstrap/packages/upgrade.html).

Flatpak updates both per-user and default system applications and runtimes when installed. Optional managers that are absent are skipped. Independent update steps continue after failures, with a final failure summary and nonzero exit status. OS and bootstrap updates may request sudo credentials. No automatic reboot is performed.

Apply your chosen profile to deploy the updater and refresh the environment, then reload your shell:

```sh
mise -E workstation dot apply
source ~/.bashrc
```

Use `server` on a server. The updater requires the recorded repository and valid profile when mise is installed, rather than guessing from a desktop session or SSH connection. After moving the repository, rerun the setup helper from its new location. After moving the repository or changing profiles, apply again and reload your shell. You can explicitly override `DOTFILES_REPO` and `DOTFILES_PROFILE` for a run.

## Resources / References
- [mise - Dotfiles](https://mise.jdx.dev/dotfiles.html)
