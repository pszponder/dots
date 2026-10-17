# Git configuration

Shared defaults live in this repository; machine-local settings live in Git's global configuration files. Applying dotfiles updates the shared files without replacing your local Git configuration.

## Files and ownership

| Repository source | Installed path | Purpose |
| --- | --- | --- |
| `dots/.config/git/defaults` | `~/.config/git/defaults` (symlink) | Shared aliases, editor, diff settings, and conditional includes |
| `dots/.config/git/dotfiles-identity.tera` | `~/.config/git/dotfiles-identity` (rendered file) | Default author name and email from mise variables |
| `dots/.config/git/github_pszponder` | `~/.config/git/github_pszponder` (symlink) | SSH key selection for matching personal GitHub repositories |
| None | `~/.config/git/config` and `~/.gitconfig` | User-owned global settings and overrides |

Paths here assume the default XDG configuration directory. With `XDG_CONFIG_HOME` set, the setup helper attaches includes in `$XDG_CONFIG_HOME/git/config`; dotfile deployment paths remain those declared in the mise manifest.

`defaults` and `dotfiles-identity` are names chosen by this repository. Git does not discover them automatically. The setup helper prepends these includes to `~/.config/git/config`, using absolute paths for your machine:

```gitconfig
[include]
    path = /home/YOUR_USER/.config/git/dotfiles-identity
    path = /home/YOUR_USER/.config/git/defaults

# Existing machine-local settings follow the includes.
```

Full bootstrap and `mise run dotfiles:apply` run this helper after deployment. To attach the includes separately, run `mise run setup:git` from the checkout. Repeated setup preserves existing settings and does not duplicate the includes. The helper refuses to edit a symlinked XDG Git config to avoid writing through it into another source file.

## Precedence

Git reads system configuration, the XDG global config, `~/.gitconfig`, and repository-local `.git/config` in that order. Includes are read where they appear. For ordinary single-valued settings, the last value wins; multi-valued settings such as credential helpers can accumulate values. See the [Git configuration reference](https://git-scm.com/docs/git-config#_files).

With this setup, identity defaults load first, shared defaults next, and existing XDG settings afterward. Settings in `~/.gitconfig` override those global defaults, and repository-local settings override global settings. Worktree configuration, when enabled, and command-line `git -c` settings can override these further.

The shared defaults conditionally include `github_pszponder` for repositories under `~/repos/github/pszponder/`. This selects the personal SSH key; it does not change author name or email. See [SSH configuration](ssh_configuration.md).

## Changing settings

For shared defaults, edit `dots/.config/git/defaults`. Its deployed symlink makes changes live immediately. Do not put credentials or machine-specific values there.

For default author identity, save mise variables and reapply from the checkout:

```sh
mise vars prompt git_name="Your Name" git_email="you@example.com"
mise run dotfiles:apply
```

For machine-local overrides, use Git's normal commands:

```sh
git config --global user.email "machine@example.com"
git config --global core.editor "vim"
```

Git writes to `~/.gitconfig` if it exists, otherwise to the existing XDG global config. These local settings survive dotfile reapplication and override included defaults. For a single repository, run `git config --local user.email "project@example.com"` inside that repository.

To return to an included default, remove the corresponding override from the file that defines it. Changing mise's identity variables will not override a local `user.name` or `user.email` value.

## Inspecting effective values and migration

Run these commands inside the repository you want to inspect, so conditional includes and local settings apply:

```sh
git config --show-origin --show-scope --list
git config --show-origin --get user.email
git config --show-origin --get core.sshCommand
```

When inspecting only global configuration, use `git config --global --includes --list` to explicitly expand includes.

Migration from the old `config.tera` deployment preserves the existing rendered global config. Its old settings now act as local overrides and can mask later changes to shared defaults. Review their origins with the commands above and remove duplicated settings you want the shared files to control. Keep the include directives and any intentional local overrides.
