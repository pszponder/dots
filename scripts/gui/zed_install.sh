#!/bin/sh
set -eu

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if command -v zed >/dev/null 2>&1; then
    log_info "Zed is already installed: $(command -v zed)"
    return 0
  fi

  [ "$(uname -s)" = Linux ] || {
    log_info 'Skipping Zed installation: the native installer is for Linux'
    return 0
  }
  command -v curl >/dev/null 2>&1 || {
    log_error 'curl is required to install Zed'
    return 1
  }

  # Download first so a failed curl cannot be hidden by a successful pipeline.
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  trap 'exit 1' HUP INT TERM
  curl --fail --silent --show-error --location --retry 3 \
    https://zed.dev/install.sh --output "$installer"
  sh "$installer"
  log_success 'Zed installed with the official native installer'
}

main "$@"
