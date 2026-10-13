#!/bin/sh
set -eu

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

main() {
  [ "$(uname -s)" = Linux ] || return 0
  [ -r /etc/os-release ] || return 0
  . /etc/os-release

  case "${ID:-}" in
    fedora)
      # DNF's enable command is safe to repeat for an already-enabled COPR.
      as_root dnf copr enable -y scottames/ghostty
      ;;
  esac
}

main "$@"
