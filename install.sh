#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
LOGGING_LIB="$SCRIPT_DIR/scripts/utils/utils_logging.sh"
if [ ! -f "$LOGGING_LIB" ]; then
  printf 'Error: logging helpers not found at %s\n' "$LOGGING_LIB" >&2
  exit 1
fi
# shellcheck source=scripts/utils/utils_logging.sh
. "$LOGGING_LIB"

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/pszponder/dots.git}"
REPO_DIR="${DOTFILES_REPO_DIR:-$HOME/repos/github/pszponder/dots}"

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
    curl https://mise.run | sh
  fi

  export PATH="$HOME/.local/bin:$PATH"
  command -v mise >/dev/null 2>&1 || die "mise installation finished, but mise is not on PATH"
}

choose_profile() {
  profile=${1:-}

  if [ -z "$profile" ]; then
    printf 'Select setup profile:\n  1) workstation\n  2) server\n'
    printf 'Profile [1]: '
    IFS= read -r profile
    profile="${profile:-1}"
    case "$profile" in
      1) profile=workstation ;;
      2) profile=server ;;
    esac
  fi

  case "$profile" in
    workstation|server) printf '%s\n' "$profile" ;;
    *) die "profile must be 'workstation' or 'server'" ;;
  esac
}

if [ -f "$SCRIPT_DIR/mise.toml" ]; then
  REPO_DIR="$SCRIPT_DIR"
else
  command -v git >/dev/null 2>&1 || die "git is required to download the dotfiles repository"
  if [ ! -d "$REPO_DIR/.git" ]; then
    log_info "Cloning dotfiles into $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
fi

[ -f "$REPO_DIR/mise.toml" ] || die "could not find mise.toml in $REPO_DIR"
install_mise

profile="$(choose_profile "${1:-}")"
cd "$REPO_DIR"

log_info "Trusting mise configuration in $REPO_DIR"
mise trust

log_info "Previewing $profile setup"
mise -E "$profile" bootstrap --dry-run

if [ -t 0 ]; then
  printf 'Apply this setup now? [y/N] '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) log_warn "Setup cancelled"; exit 0 ;;
  esac
else
  log_info "Applying $profile setup"
fi

mise -E "$profile" bootstrap
log_success "Setup complete"
