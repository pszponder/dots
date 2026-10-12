#!/bin/sh
set -eu

install_development_tools() {
  # DNF package groups cannot be checked as individual RPM packages by mise.
  [ -r /etc/os-release ] || return 0
  . /etc/os-release
  [ "${ID:-}" = fedora ] || return 0
  command -v dnf >/dev/null 2>&1 || {
    log_error "Fedora bootstrap requires dnf on PATH"
    exit 1
  }

  # DNF keeps an already-installed group; repeating this is safe.
  if [ "$(id -u)" -eq 0 ]; then
    dnf group install -y development-tools
  else
    sudo dnf group install -y development-tools
  fi
}

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  install_development_tools
}

main "$@"
