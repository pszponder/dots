# Dotfiles with mise

Linux workstation and server dotfiles, with explicit deployment through mise. This repository is independent of any desktop distribution.

See [mise setup and usage](docs/mise.md), [directory structure](docs/directory_structure.md), and [SSH configuration](docs/ssh_configuration.md).

```sh
mise trust
mise -E workstation vars prompt
mise -E workstation bootstrap --dry-run
mise -E workstation bootstrap
```

Use `server` instead of `workstation` on servers. Both profiles bootstrap directories, SSH keys, and Nerd Fonts. Workstation also installs Flatpak if missing and configures the per-user Flathub remote. Missing SSH keys prompt for passphrases. Review the dry run before applying.

## TODOs

- [ ] Set up Git configuration
- [ ] Configure Flatpak applications (through mise bootstrap)
- [ ] Create install.sh which will download / install mise, and start bootstrap / setup process (it should detect if homeberw is install and install mise using homebrew but if not available, use the official installer tool to install mise instead)

## Resources / References
- [mise](https://mise.jdx.dev)
