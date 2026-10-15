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
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  [ "$(uname -s)" = Linux ] || return 0
  [ -r /etc/os-release ] || return 0
  . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *' debian '*|*' ubuntu '*) ;;
    *) return 0 ;;
  esac

  keyring=/usr/share/keyrings/helium.gpg
  source_list=/etc/apt/sources.list.d/helium.list
  if [ -f "$keyring" ] && [ -f "$source_list" ]; then
    log_info 'Helium apt repository is already configured'
    return 0
  fi

  command -v curl >/dev/null 2>&1 || {
    log_error 'curl is required to configure the Helium repository'
    return 1
  }
  command -v gpg >/dev/null 2>&1 || {
    log_error 'gpg is required to configure the Helium repository'
    return 1
  }

  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT
  trap 'exit 1' HUP INT TERM
  curl --fail --silent --show-error --location --retry 3 \
    https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc \
    --output "$temp_dir/pubkey.asc"
  gpg --batch --yes --dearmor --output "$temp_dir/helium.gpg" "$temp_dir/pubkey.asc"
  printf '%s\n' \
    'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main' \
    > "$temp_dir/helium.list"
  as_root install -Dm0644 "$temp_dir/helium.gpg" "$keyring"
  as_root install -Dm0644 "$temp_dir/helium.list" "$source_list"
  as_root apt-get update
  log_success 'Helium apt repository configured'
}

main "$@"
