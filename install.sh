#!/bin/sh

set -eu

initialize() {
  SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  LOGGING_LIB="$SCRIPT_DIR/scripts/utils/utils_logging.sh"
  if [ ! -f "$LOGGING_LIB" ]; then
    # A downloaded installer has no checkout yet.
    log_info() { printf 'INFO: %s\n' "$*"; }
    log_success() { printf 'OK: %s\n' "$*"; }
    log_warn() { printf 'WARN: %s\n' "$*" >&2; }
    log_error() { printf 'ERROR: %s\n' "$*" >&2; }
  else
    # shellcheck source=scripts/utils/utils_logging.sh
    . "$LOGGING_LIB"
  fi

  REPO_URL="${DOTFILES_REPO_URL:-https://github.com/pszponder/dots.git}"
  REPO_DIR="${DOTFILES_REPO_DIR:-$HOME/repos/github/pszponder/dots}"
}

die() {
  log_error "$*"
  exit 1
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    log_info "mise is already installed: $(command -v mise)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    log_info "Installing mise with Homebrew"
    brew install mise
  else
    command -v curl >/dev/null 2>&1 || die "curl is required to install mise"
    log_info "Installing mise with the official installer"
    curl -fsSL https://mise.run | sh
  fi

  export PATH="$HOME/.local/bin:$PATH"
  command -v mise >/dev/null 2>&1 || die "mise installation finished, but mise is not on PATH"
}

detect_workstation_profile() {
  ID= ID_LIKE=
  [ -r /etc/os-release ] || die "Cannot detect distribution; select workstation-ubuntu, workstation-debian, workstation-fedora, workstation-arch, or workstation-ublue explicitly"
  . /etc/os-release
  case " $ID $ID_LIKE " in
    *' bluefin '*|*' bazzite '*|*' aurora '*|*' ublue '*) printf 'workstation-ublue\n'; return ;;
  esac
  case "$ID" in
    ubuntu|debian|fedora|arch) printf 'workstation-%s\n' "$ID"; return ;;
  esac
  # Follow the distribution's declared ancestry order.
  for family in $ID_LIKE; do
    case "$family" in
      ubuntu|debian|fedora|arch) printf 'workstation-%s\n' "$family"; return ;;
    esac
  done
  die "Unsupported workstation distribution: ${ID:-unknown}; select a supported workstation-<distribution> profile explicitly"
}

choose_profile() {
  profile=${1:-}

  if [ -z "$profile" ] && [ ! -t 0 ]; then
    die "No terminal available; pass a profile explicitly (for example: sh -s -- server)"
  fi

  if [ -z "$profile" ]; then
    printf 'Select setup profile:\n  1) workstation (detect distribution automatically)\n  2) server\n  3) workstation-ubuntu\n  4) workstation-debian\n  5) workstation-fedora\n  6) workstation-arch\n  7) workstation-ublue (Universal Blue)\n' >&2
    printf 'Profile [1]: ' >&2
    IFS= read -r profile
    profile="${profile:-1}"
    case "$profile" in
      1) profile=workstation ;;
      2) profile=server ;;
      3) profile=workstation-ubuntu ;;
      4) profile=workstation-debian ;;
      5) profile=workstation-fedora ;;
      6) profile=workstation-arch ;;
      7) profile=workstation-ublue ;;
    esac
  fi

  case "$profile" in
    workstation) detect_workstation_profile ;;
    workstation-ubuntu|workstation-debian|workstation-fedora|workstation-arch|workstation-ublue|server) printf '%s\n' "$profile" ;;
    *) die "profile must be workstation, server, or workstation-{ubuntu,debian,fedora,arch,ublue}" ;;
  esac
}

configure_ssh_remote() {
  origin_url=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null) || return 0
  case "$origin_url" in
    https://github.com/*)
      ssh_url="git@github.com:${origin_url#https://github.com/}"
      git -C "$REPO_DIR" remote set-url origin "$ssh_url"
      log_info "Switched origin to SSH: $ssh_url"
      ;;
  esac
}

main() {
  initialize
  DOTFILES_YES=0
  selected_profile=
  for argument in "$@"; do
    case "$argument" in --yes|-y) DOTFILES_YES=1 ;; *) [ -z "$selected_profile" ] || die "Pass one profile"; selected_profile=$argument ;; esac
  done
  export DOTFILES_YES
  set -- "$selected_profile"

  if [ -z "${1:-}" ] && [ ! -t 0 ]; then
    # curl | sh uses stdin for the script; read interactive input from the terminal.
    if ( : < /dev/tty ) 2>/dev/null; then
      exec < /dev/tty
    else
      die "No terminal available; pass a profile explicitly (for example: sh -s -- server)"
    fi
  fi

  if [ -f "$SCRIPT_DIR/bootstrap/mise.toml" ]; then
    REPO_DIR="$SCRIPT_DIR"
  else
    command -v git >/dev/null 2>&1 || die "git is required to download the dotfiles repository"
    if [ ! -d "$REPO_DIR/.git" ]; then
      log_info "Cloning dotfiles into $REPO_DIR"
      mkdir -p "$(dirname "$REPO_DIR")"
      git clone "$REPO_URL" "$REPO_DIR"
    fi
  fi

  [ -f "$REPO_DIR/bootstrap/mise.toml" ] || die "could not find bootstrap/mise.toml in $REPO_DIR"
  profile="$(choose_profile "${1:-}")"

  log_info "Preparation installs mise if needed, links global mise configs, offers a force retry if linking fails, and saves trust"
  if [ -t 0 ] && [ "$DOTFILES_YES" != 1 ]; then
    printf 'Prepare global mise configuration before previewing bootstrap? [y/N] '
    IFS= read -r answer
    case "$answer" in
      y|Y|yes|YES|Yes) ;;
      *) log_warn "Setup cancelled before global mise preparation"; exit 0 ;;
    esac
  fi
  install_mise

  log_info "Linking global mise tool configuration"
  mise -C "$REPO_DIR/bootstrap" -E "$profile" config --json >/dev/null
  sh "$REPO_DIR/scripts/bootstrap/configure_mise.sh" "$REPO_DIR" "$profile"

  if [ -t 0 ] && [ "$DOTFILES_YES" != 1 ]; then
    log_info "Collecting missing setup variables"
    # Prompt before loading bootstrap, whose templates may need these values.
    mise -C "${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}" vars prompt
  fi

  cd "$REPO_DIR/bootstrap"
  log_info "Trusting mise configuration in $REPO_DIR"
  mise trust

  log_info "Previewing $profile setup"
  mise -E "$profile" bootstrap --dry-run --force-dotfiles

  if [ -t 0 ] && [ "$DOTFILES_YES" != 1 ]; then
    printf 'Apply bootstrap now? (Global mise preparation is already complete.) [y/N] '
    IFS= read -r answer
    case "$answer" in
      y|Y|yes|YES|Yes) ;;
      *) log_warn "Setup cancelled"; exit 0 ;;
    esac
  else
    log_info "Applying $profile setup"
  fi

  sh "$REPO_DIR/scripts/bootstrap/retry_mise.sh" bootstrap -E "$profile"
  mise -E "$profile" bootstrap status
  configure_ssh_remote
  log_success "Setup complete"
  log_info "Open a new shell, then run 'mise doctor' to verify shell activation"
  # With curl | sh, stdin now points at /dev/tty for prompts. Exit before
  # the shell tries to read another command from that terminal.
  exit 0
}

main "$@"
