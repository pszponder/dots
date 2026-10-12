#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../utils/utils_logging.sh"

if [ "$(uname -s)" != "Linux" ]; then
  exit 0
fi

# Prepare Flatpak before mise applies the workstation's application declarations.
if ! command -v flatpak >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    set -- apt-get install -y flatpak
  elif command -v dnf >/dev/null 2>&1; then
    set -- dnf install -y flatpak
  elif command -v pacman >/dev/null 2>&1; then
    set -- pacman -S --needed --noconfirm flatpak
  else
    log_error 'Cannot install Flatpak: expected apt-get, dnf, or pacman'
    exit 1
  fi

  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log_success 'User Flathub remote configured'
