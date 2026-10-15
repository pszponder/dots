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
    *' debian '*|*' ubuntu '*) format=deb; manager=apt-get ;;
    *' fedora '*|*' rhel '*) format=rpm; manager=dnf ;;
    *) return 0 ;;
  esac

  if command -v yaak >/dev/null 2>&1; then
    log_info 'Yaak is already installed'
    return 0
  fi
  case "$(uname -m)" in
    x86_64) release_arch=x86_64; deb_arch=amd64; rpm_arch=x86_64 ;;
    aarch64|arm64) release_arch=arm_64; deb_arch=arm64; rpm_arch=aarch64 ;;
    *) log_info 'Skipping Yaak installation: unsupported architecture'; return 0 ;;
  esac
  command -v curl >/dev/null 2>&1 || {
    log_error 'curl is required to install Yaak'
    return 1
  }
  command -v "$manager" >/dev/null 2>&1 || {
    log_error "$manager is required to install Yaak"
    return 1
  }

  # Official download links from https://yaak.app/download.
  version=2026.9.0
  case "$format" in
    deb) filename="yaak-cef_${version}_${deb_arch}.deb" ;;
    rpm) filename="yaak-${version}-1.${rpm_arch}.rpm" ;;
  esac
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT
  trap 'exit 1' HUP INT TERM
  package="$temp_dir/$filename"
  curl --fail --silent --show-error --location --retry 3 \
    "https://yaak.app/releases/v${version}/${format}-${release_arch}/${filename}" \
    --output "$package"
  # apt's download sandbox must be able to read the local package.
  chmod 0755 "$temp_dir"
  chmod 0644 "$package"
  as_root "$manager" install -y "$package"
  log_success "Yaak $version installed from the official $format package"
}

main "$@"
