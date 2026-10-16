#!/bin/sh
set -eu

skip() { log_info "Skipping Flox installation: $*"; exit 0; }

check_platform() {
  case "$(uname -m)" in
    x86_64|aarch64|arm64) ;;
    *) skip 'unsupported CPU architecture' ;;
  esac

  case "$(uname -s)" in
    Darwin) ;;
    Linux)
      [ -r /etc/os-release ] || skip 'cannot identify Linux distribution'
      . /etc/os-release
      [ ! -e /run/ostree-booted ] && [ ! -d /ostree ] || skip 'immutable Linux distribution'
      case " ${ID:-} ${ID_LIKE:-} " in
        *' opensuse '*|*' suse '*|*' sles '*) skip 'unsupported SUSE distribution' ;;
        *' debian '*|*' ubuntu '*) command -v apt-get >/dev/null 2>&1 || skip 'apt-get is unavailable' ;;
        *' fedora '*|*' rhel '*|*' centos '*)
          command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1 || skip 'dnf/yum is unavailable' ;;
        *) skip 'the official installer does not support this Linux distribution' ;;
      esac ;;
    *) skip 'unsupported operating system' ;;
  esac

  # The official script refuses existing Nix installations; leave them intact.
  if command -v nix >/dev/null 2>&1 || [ -d /nix/store ]; then
    skip 'Nix is already installed; see https://flox.dev/docs/install-flox/install#generic-nix'
  fi
}

install_flox() {
  command -v curl >/dev/null 2>&1 || { log_error 'curl is required to install Flox'; exit 1; }

  # Download first so a failed curl cannot be hidden by a successful shell pipeline.
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  trap 'exit 1' HUP INT TERM
  curl --fail --silent --show-error --location --retry 3 https://get.flox.dev --output "$installer"
  sh "$installer"
  flox --version
  log_success 'Flox installed; run flox auth login and flox init --default to set up your default environment'
}

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if command -v flox >/dev/null 2>&1; then
    log_info "Flox is already installed: $(command -v flox)"
  else
    check_platform
    install_flox
  fi

  flox config --set auth_notifications false
  log_success 'Flox login reminders disabled'
}

main "$@"
