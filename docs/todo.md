# TODOs

- [ ] Check out [Project scaffolding tasks | mise-en-place](https://mise.jdx.dev/mise-cookbook/presets.html) (I would want the scaffolding task to create a python project with pytest as a dev dependency, maybe don't create a bare project but an application ([Creating projects | uv](https://docs.astral.sh/uv/concepts/projects/init/)))
- [ ] Configure Flatpak applications (through mise bootstrap)
- [ ] Determine if need to install from [snaps](https://github.com/jdx/mise/pull/14402)
- [ ] Determine if need to install COPR repositories (https://github.com/jdx/mise/pull/14401)
- [ ] Install GUIs on Workstation
  - [ ] Zed (flatpak or through official curl installation?)
  - [ ] Podman Desktop (does it conflict w/ Rancher Desktop?)
  - [ ] Rancher Desktop (does it conflict w/ Podman Desktop?)
  - [ ] Yaak (API Client)
  - [ ] Ghostty (https://github.com/jdx/mise/pull/14401)
- [ ] Install Services (on all machines)
  - [ ] Podman

## Done
- [x] Configure desktop background?
- [x] Review my old dotfiles and import other configurations ([migration notes](dotfiles_migration.md))
- [x] Review tmux and herdr bindings/configs. Should we make both use default tmux bindings?
- [x] Should we integrate [fff.nvim](https://github.com/dmtrKovalenko/fff#fffnvim) into our nvim config? -> Didn't integrate, maybe in the future