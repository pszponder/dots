# Dotfiles with mise

Manage Linux dotfiles and bootstrap workstation/server environments from a private Git repository.

This repository uses explicit deployment: edit source files, review changes, and apply them. Automatic history synchronization is optional and is not enabled here.

## Current bootstrap configuration

Dotfile sources live under `dots/` and mirror their home-directory paths. The active configuration deploys the portable Bash and Zsh startup files, shared aliases and environment, Git defaults, Starship, tmux, Nerd Fonts selection, and the SSH key helper. Mise renders `.tera` files, links individual files in shared config directories, and uses `[dotfiles]` in `mise.toml` to declare those targets.

From the repository, select one profile:

```sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
# On servers, replace workstation with server.
```

Both profiles install OpenSSH using apt, pacman, or dnf, create the directories in `[bootstrap.directories]`, deploy the helper/environment files, and run the final SSH key hook. Run in a terminal: missing keys prompt for passphrases. Existing keys remain untouched. See [SSH setup](ssh_configuration.md) and [directory structure](directory_structure.md).

The workstation profile also installs Flatpak through apt, pacman, or dnf if it is missing. An existing installation satisfies the `"latest"` declaration. The server profile does not install Flatpak. After package installation, a workstation `post-packages` hook runs `scripts/gui/flatpak_install.sh` to add the per-user Flathub remote with `flatpak remote-add --user --if-not-exists`. Existing user remotes are preserved. This matches the `--user` scope used by `flatpak_sync.sh`. Application manifests are configured separately. See [Flatpak remotes](https://docs.flatpak.org/en/latest/using-flatpak.html#add-a-remote).

Both profiles install curl, tar, XZ support, fontconfig, Git, and OpenSSH through the supported system package manager, then install CaskaydiaCove, CaskaydiaMono, and JetBrainsMono under `~/.local/share/fonts/NerdFonts` (or `$XDG_DATA_HOME/fonts/NerdFonts`). Fedora declares `openssh-clients`, `xz`, `fontconfig`, and `tar` for SSH and font installation.

Edit `dots/.config/nerd-fonts/fonts` to select font families and `nerdfonts_version` in `mise.toml` to select a release. The installer downloads official [Nerd Fonts release archives](https://github.com/ryanoasis/nerd-fonts/releases), records each installed version, skips matching installed families, and refreshes the font cache after changes. Removing a family from the manifest leaves its installed files in place. Font selection in terminal applications is configured separately.

Bootstrap final hooks run on every bootstrap, including when keys and fonts already exist. `dot apply` deploys sources but does not run these final hooks. Bootstrap status describes declarative resources, but does not verify SSH key or font installer state. A dry run prints the final hooks without generating keys or downloading fonts. See [mise bootstrap run order](https://mise.jdx.dev/bootstrap.html#run-order).

The rendered `~/.config/env.sh` contains the repository location, selected profile, and shared shell environment. Managed Bash and Zsh startup files load it directly. Reapply from the new location and reload your shell after moving the repository.

## Example expanded repository layout

```
dotfiles/
├── README.md
├── .gitignore
├── mise.toml
├── mise.workstation.toml
├── mise.server.toml
└── dots/
    ├── .bashrc
    ├── .zshenv
    └── .config/
        └── env.sh.tera
```

Source paths are relative to the mise configuration file that declares them.

## Configure the repository

Put shared configuration in `mise.toml`:

```
[vars]
dotfiles_repo = "{{ config_root }}"

[vars.git_name]
required = "Set your Git author name"
prompt = "Git author name"

[vars.git_email]
required = "Set your Git email"
prompt = "Git email"

[dotfiles]
"~/.bashrc" = { source = "dots/bash/bashrc", mode = "symlink" }
"~/.config/git/config" = { source = "dots/.config/git/config.tera", mode = "template" }
"~/.config/nvim" = { source = "dots/nvim", mode = "symlink" }
"~/.config/starship.toml" = { source = "dots/starship/starship.toml", mode = "copy" }
"~/.config/env.sh" = { source = "dots/.config/env.sh.tera", mode = "template" }

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
  source = "dots/kitty/kitty.conf",
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

Shared, non-sensitive defaults can be committed in `[vars]`. Local overrides can go in the ignored `mise.local.toml`:

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
git add dots/ mise.toml mise.workstation.toml mise.server.toml
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

Copy the existing file into `dots/`, then add its mapping to `mise.toml` or the relevant profile:

```
[dotfiles]
"~/.config/example/config.toml" = {
  source = "dots/example/config.toml",
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

Declare a secret input in `mise.toml`:

```
[bootstrap.secrets]
api_token = "MY_API_TOKEN"

[dotfiles."~/.config/example/credentials"]
source = "dots/example/credentials.tera"
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

If you add `[tools]` to this repository’s `mise.toml`, those tool selections apply within the repository’s configuration scope. For tools you want available throughout your home directory, manage a separate global `~/.config/mise/config.toml`.

Configure [mise shell activation](https://mise.jdx.dev/getting-started.html) in your managed shell startup file when using mise-installed tools interactively.

## Update tools and packages from any directory

The shared configuration records the repository path with `config_root`, and each profile sets `dotfiles_profile`. The managed `dots/.config/env.sh.tera` includes these exports alongside the shared shell environment:

```jinja
export DOTFILES_REPO={{ vars.dotfiles_repo | quote }}
export DOTFILES_PROFILE={{ vars.dotfiles_profile | quote }}
```

The `quote` filter formats values safely for Bash, including paths containing spaces. See [mise templates](https://mise.jdx.dev/templates.html).

The managed Bash and Zsh startup files source `~/.config/env.sh`, so the values are available without an extra source snippet. For example, a Bash `up` function can use them like this:

```bash
up() {
    local repo="${DOTFILES_REPO:?Apply your dotfiles profile first}"
    local profile="${DOTFILES_PROFILE:?Apply your dotfiles profile first}"

    mise -C "$repo" -E "$profile" upgrade &&
        mise -C "$repo" -E "$profile" bootstrap packages upgrade
}
```

From the repository, apply your machine's profile and reload Bash:

```sh
mise -E workstation dot apply
mise exec gh@latest -- gh auth setup-git --hostname github.com
source ~/.bashrc
```

Use `server` instead of `workstation` on a server. Apply with an explicit profile so the environment template has a `dotfiles_profile` value. The initial bootstrap renders `~/.config/env.sh`.

Then run `up` from any directory. It upgrades `[tools]` within their configured version ranges, then upgrades `[bootstrap.packages]` if the tool upgrade succeeds. It does not pull repository changes or reapply dotfiles. See [tool upgrades](https://mise.jdx.dev/cli/upgrade.html) and [bootstrap packages](https://mise.jdx.dev/bootstrap/packages/).

`up` is a Bash function; `mise up` remains mise's built-in tool upgrade command. Mise does not automatically interpret `DOTFILES_REPO` or `DOTFILES_PROFILE`: the function supplies `-C` and `-E` explicitly. Repository tool selections still apply within the repository's scope; use global configuration for tools you want active everywhere.

After moving the repository or switching profiles, apply again from the repository's current location and reload Bash to refresh the exported values. If you moved the repository, repair any existing symlinks that still point to its old location before reloading.

## Resources / References
- [mise - Dotfiles](https://mise.jdx.dev/dotfiles.html)
