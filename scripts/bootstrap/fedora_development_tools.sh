#!/bin/sh
set -eu

# DNF package groups cannot be checked as individual RPM packages by mise.
[ -r /etc/os-release ] || exit 0
. /etc/os-release
[ "${ID:-}" = fedora ] || exit 0
command -v dnf >/dev/null 2>&1 || {
  printf '%s\n' 'Fedora bootstrap requires dnf on PATH' >&2
  exit 1
}

# DNF keeps an already-installed group; repeating this is safe.
if [ "$(id -u)" -eq 0 ]; then
  dnf group install -y development-tools
else
  sudo dnf group install -y development-tools
fi
