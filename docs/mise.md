# Dotfiles with mise

Manage Linux dotfiles and bootstrap workstation/server environments from a private Git repository.

This repository uses explicit deployment: edit source files, review changes, and apply them. Automatic history synchronization is optional and is not enabled here.

## Current bootstrap configuration

Dotfile sources live under `dots/` and mirror their home-directory paths. The active configuration deploys the portable Bash and Zsh startup files, shared aliases and environment, Git defaults, Starship, tmux, Nerd Fonts selection, and the SSH key helper. Mise renders `.tera` files, links individual files in shared config directories, and uses `[dotfiles]` in `dots/.config/mise/config.toml` to declare those targets.

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

The workstation profile's `pre-packages` hook runs `scripts/gui/flatpak_install.sh` to install the Flatpak CLI through apt, dnf, or pacman if missing, then add the per-user Flathub remote with `flatpak remote-add --user --if-not-exists`. Existing user remotes are preserved. Mise then installs the applications declared under `[bootstrap.packages]`, including Zed. Add more apps to `dots/.config/mise/config.workstation.toml` as `"flatpak-user:APPLICATION_ID" = "latest"` to match the hook's user scope. The server profile does not install Flatpak. See [mise Flatpak packages](https://mise.jdx.dev/bootstrap/packages/flatpak.html).

Both profiles install curl, tar, XZ support, fontconfig, Git, and OpenSSH through the supported system package manager, then install CaskaydiaCove, CaskaydiaMono, and JetBrainsMono under `~/.local/share/fonts/NerdFonts` (or `$XDG_DATA_HOME/fonts/NerdFonts`). Fedora declares `openssh-clients`, `xz`, `fontconfig`, and `tar` for SSH and font installation.

Edit `dots/.config/nerd-fonts/fonts` to select font families and `nerdfonts_version` in `dots/.config/mise/config.toml` to select a release. The installer downloads official [Nerd Fonts release archives](https://github.com/ryanoasis/nerd-fonts/releases), records each installed version, skips matching installed families, and refreshes the font cache after changes. Removing a family from the manifest leaves its installed files in place. Font selection in terminal applications is configured separately.

Bootstrap final hooks run on every bootstrap, including when keys and fonts already exist. `dot apply` deploys sources but does not run these final hooks. Bootstrap status describes declarative resources, but does not verify SSH key or font installer state. A dry run prints the final hooks without generating keys or downloading fonts. See [mise bootstrap run order](https://mise.jdx.dev/bootstrap.html#run-order).

The rendered `~/.config/env.sh` contains the repository location, selected profile, and shared shell environment. Managed Bash and Zsh startup files load it directly. After moving the repository, rerun `sh scripts/bootstrap/configure_mise.sh` from the new checkout, reapply, and reload your shell.

## Example expanded repository layout

```
dotfiles/
├── README.md
├── .gitignore
├── mise.toml
└── dots/
    ├── .bashrc
    ├── .zshenv
    └── .config/
        ├── env.sh.tera
        └── mise/
            ├── config.toml
            ├── config.workstation.toml
            └── config.server.toml
```

Source paths resolve through the `dotfiles` link in the global mise directory, which points to the checkout. Hooks use `vars.dotfiles_repo` from machine-local checkout context.

## Configure the repository

Put shared configuration in `dots/.config/mise/config.toml`:

```
[vars]

[vars.git_name]
required = "Set your Git author name"
prompt = "Git author name"

[vars.git_email]
required = "Set your Git email"
prompt = "Git email"

[dotfiles]
"~/.bashrc" = { source = "dotfiles/dots/bash/bashrc", mode = "symlink" }
"~/.config/git/config" = { source = "dotfiles/dots/.config/git/config.tera", mode = "template" }
"~/.config/nvim" = { source = "dotfiles/dots/nvim", mode = "symlink" }
"~/.config/starship.toml" = { source = "dotfiles/dots/starship/starship.toml", mode = "copy" }
"~/.config/env.sh" = { source = "dotfiles/dots/.config/env.sh.tera", mode = "template" }

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

Add workstation configuration in `dots/.config/mise/config.workstation.toml`:

```
[vars]
dotfiles_profile = "workstation"

[dotfiles]
"~/.config/kitty/kitty.conf" = {
  source = "dotfiles/dots/kitty/kitty.conf",
  mode = "symlink"
}

[bootstrap.packages]
"apt:kitty" = "latest"
"pacman:kitty" = "latest"
```

Add server configuration in `dots/.config/mise/config.server.toml`:

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
.env
.env.*
```

## Choose deployment modes

| Mode           | Behavior                                       | Typical use                                             |
| -------------- | ---------------------------------------------- | ------------------------------------------------------- |
| `symlink`      | Links the live path to the repository source   | Files you edit yourself                                 |
| `symlink-each` | Creates directories and links individual files | Shared config directories where unrelated files must remain |
| `copy`         | Writes an independent copy                     | Applications that rewrite configuration                 |
| `template`     | Renders a template into a regular file         | Values that vary between machines                       |

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

Before the first apply, review and back up existing target files. For symlink mappings, move conflicting files or directories out of the way; copying a backup alone leaves the conflict unresolved. For example, after copying any settings you want into `dots/bash/bashrc`:

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
mise -E workstation vars prompt
mise -E server bootstrap --dry-run
mise -E server bootstrap
mise exec gh@latest -- gh auth setup-git --hostname github.com
mise -E server bootstrap status
```

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
git add dots/ mise.toml
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

Copy the existing file into `dots/`, then add its mapping to `dots/.config/mise/config.toml` or the relevant profile:

```
[dotfiles]
"~/.config/example/config.toml" = {
  source = "dotfiles/dots/example/config.toml",
  mode = "copy"
}
```

Review and apply:

```
mise -E workstation dot diff
mise -E workstation dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com
```

Commit the source file and its configuration mapping together.

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

Declare a secret input in `dots/.config/mise/config.toml`:

```
[bootstrap.secrets]
api_token = "MY_API_TOKEN"

[dotfiles."~/.config/example/credentials"]
source = "dotfiles/dots/example/credentials.tera"
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

Deleting a mapping stops managing the target but leaves it on disk.

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

All tools, OS packages, dotfiles, directories, and hooks are declared under `dots/.config/mise/` and linked into the global mise directory:

- `config.toml` declares shared setup, including Codex and Claude Code.
- `config.server.toml` adds Herdr for servers.
- `config.workstation.toml` adds workstation setup, including Flatpak.

Tool declarations use `[tools]`; OS packages use `[bootstrap.packages]`. The shared file merges with the selected profile; the managed shell environment exports `MISE_ENV="$DOTFILES_PROFILE"`. Global versions are user-wide defaults that project configuration can override.

Run `sh scripts/bootstrap/configure_mise.sh` once before direct bootstrap, or use `install.sh`, which runs it automatically. The helper links the configs and checkout and writes `conf.d/00-dotfiles-context.toml` with the checkout path. Existing conflicting mise configs are moved to a backup directory. Bootstrap then installs configured tools in its normal tools phase, including on the first run. Rerun the helper after moving the checkout, then bootstrap and reload your shell. `dot apply` only deploys files; run `mise -E <profile> install` afterward to install newly declared tools without a full bootstrap. Tool installation does not configure CLI authentication.

Configure [mise shell activation](https://mise.jdx.dev/getting-started.html) in your managed shell startup file when using mise-installed tools interactively.

## Update tools and packages from any directory

The setup helper records the repository path in global machine-local context; root `mise.toml` supplies `config_root` when working inside the checkout. Each global profile sets `dotfiles_profile`. The managed `dots/.config/env.sh.tera` includes these exports alongside the shared shell environment:

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

Mise installed by the OS or standard Homebrew installation is upgraded through that manager. Standalone mise installations use `mise self-update`. The updater then updates mise plugins, installs missing configured tools, upgrades configured tools within their version ranges, and upgrades installed `[bootstrap.packages]`. Shared global tools and the selected global profile are included, so `latest` declarations receive new releases. Mise commands run from `DOTFILES_REPO` with the explicit server or workstation profile, including global configuration. It does not scan unrelated project configurations or upgrade unconfigured tool versions. See [tool upgrades](https://mise.jdx.dev/cli/upgrade.html) and [package upgrades](https://mise.jdx.dev/cli/bootstrap/packages/upgrade.html).

Flatpak updates both per-user and default system applications and runtimes when installed. Optional managers that are absent are skipped. Independent update steps continue after failures, with a final failure summary and nonzero exit status. OS and bootstrap updates may request sudo credentials. No automatic reboot is performed.

Apply your chosen profile to deploy the updater and refresh the environment, then reload your shell:

```sh
mise -E workstation dot apply
source ~/.bashrc
```

Use `server` on a server. The updater requires the recorded repository and valid profile when mise is installed, rather than guessing from a desktop session or SSH connection. After moving the repository, rerun the setup helper. After moving the repository or changing profiles, apply again and reload your shell. You can explicitly override `DOTFILES_REPO` and `DOTFILES_PROFILE` for a run.

## Resources / References
- [mise - Dotfiles](https://mise.jdx.dev/dotfiles.html)
