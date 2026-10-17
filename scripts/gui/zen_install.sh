#!/bin/sh
set -eu

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if command -v zen >/dev/null 2>&1 || [ -x "$HOME/.tarball-installations/zen/zen" ]; then
    log_info 'Zen is already installed'
    return 0
  fi

  [ "$(uname -s)" = Linux ] || {
    log_info 'Skipping Zen installation: the tarball installer is for Linux'
    return 0
  }
  command -v curl >/dev/null 2>&1 || {
    log_error 'curl is required to install Zen'
    return 1
  }

  # Download first so a failed curl cannot be hidden by a successful pipeline.
  # Official instructions: https://docs.zen-browser.app/guides/install-linux
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  trap 'exit 1' HUP INT TERM
  curl --fail --silent --show-error --location --retry 3 \
    https://github.com/zen-browser/updates-server/raw/refs/heads/main/install.sh \
    --output "$installer"
  bash "$installer"
  log_success 'Zen installed with the official tarball installer'
}

main "$@"
