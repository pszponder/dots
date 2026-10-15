#!/bin/sh
set -eu

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if command -v brave-origin >/dev/null 2>&1; then
    log_info "Brave Origin is already installed: $(command -v brave-origin)"
    return 0
  fi

  [ "$(uname -s)" = Linux ] || {
    log_info 'Skipping Brave Origin installation: the native installer is for Linux'
    return 0
  }
  command -v curl >/dev/null 2>&1 || {
    log_error 'curl is required to install Brave Origin'
    return 1
  }

  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  trap 'exit 1' HUP INT TERM
  curl --fail --silent --show-error --location --retry 3 \
    https://dl.brave.com/install.sh --output "$installer"
  FLAVOR=origin sh "$installer"
  log_success 'Brave Origin installed with the official Linux installer'
}

main "$@"
