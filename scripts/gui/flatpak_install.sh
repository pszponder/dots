#!/bin/sh
set -eu

install_flatpak() {
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
}

configure_flathub() {
  set -- flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
  log_success 'System Flathub remote configured'
}

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if [ "$(uname -s)" != "Linux" ]; then
    return 0
  fi

  case "${1:-}" in
    --ublue)
      command -v flatpak >/dev/null 2>&1 || {
        log_error 'Flatpak is required on ublue; enable the Flatpak installation supplied by your image'
        exit 1
      } ;;
    "") install_flatpak ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
  configure_flathub
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  log_success 'User Flathub remote configured'
}

main "$@"
