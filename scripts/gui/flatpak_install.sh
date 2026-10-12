#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../utils/utils_logging.sh"

if [ "$(uname -s)" != "Linux" ]; then
  exit 0
fi

# Package installation is declared in mise.workstation.toml.
if ! command -v flatpak >/dev/null 2>&1; then
  log_error 'Flatpak is missing; run mise -E workstation bootstrap to install it'
  exit 1
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log_success 'User Flathub remote configured'
