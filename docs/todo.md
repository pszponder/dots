# TODOs

- [ ] Configure Flatpak applications (through mise bootstrap)
- [ ] Install GUIs on Workstation
  - [ ] Zed (flatpak or through official curl installation?)
  - [ ] Podman Desktop (does it conflict w/ Rancher Desktop?)
  - [ ] Rancher Desktop (does it conflict w/ Podman Desktop?)
  - [ ] Yaak (API Client)
- [ ] Install Services (on all machines)
  - [ ] Podman
  - [ ] Docker?
- [ ] [Nvim Exrc is Criminally Underrated - YouTube](https://www.youtube.com/watch?v=fx0TGvXDrxQ)

## Done
- [x] Configure Ghostty through available package managers: Snap, apt, native mise COPR on Fedora, and pacman on Arch.
- [x] Provide README sections for bootstrap only, dotfiles only, and global tool installation.
- [x] Configure desktop background?
- [x] Review my old dotfiles and import other configurations ([migration notes](dotfiles_migration.md))
- [x] Review tmux and herdr bindings/configs. Should we make both use default tmux bindings?
- [x] Should we integrate [fff.nvim](https://github.com/dmtrKovalenko/fff#fffnvim) into our nvim config? -> Didn't integrate, maybe in the future
- [x] Check out [Project scaffolding tasks | mise-en-place](https://mise.jdx.dev/mise-cookbook/presets.html) (I would want the scaffolding task to create a python project with pytest as a dev dependency, maybe don't create a bare project but an application ([Creating projects | uv](https://docs.astral.sh/uv/concepts/projects/init/)))
