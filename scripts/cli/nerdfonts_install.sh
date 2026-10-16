#!/bin/sh
set -eu

configure_fonts() {
  FONT_VERSION=${NERDFONTS_VERSION:-v3.5.1}
  case "$FONT_VERSION" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) log_error "Invalid Nerd Fonts version: $FONT_VERSION"; exit 1 ;;
  esac
  case "$FONT_VERSION" in *[!v0-9.]*) log_error 'Invalid version characters'; exit 1 ;; esac

  case "$(uname -s)" in
    Darwin) FONT_DIR="$HOME/Library/Fonts/NerdFonts" ;;
    Linux) FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts" ;;
    *) log_error 'Nerd Fonts installation supports Linux and macOS'; exit 1 ;;
  esac

  MANIFEST=${NERDFONTS_MANIFEST:-$HOME/.config/nerd-fonts/fonts}
  if [ ! -f "$MANIFEST" ]; then
    log_error "$MANIFEST not found; run mise -E <your-profile> dot apply first (for example, server or workstation-fedora)"
    exit 1
  fi
  for tool in curl tar; do
    command -v "$tool" >/dev/null 2>&1 || { log_error "$tool is required"; exit 1; }
  done
}

install_fonts() {
  temporary_dir=$(mktemp -d)
  trap 'rm -rf "$temporary_dir"' EXIT
  trap 'exit 1' HUP INT TERM
  changed=false

  while IFS= read -r font_name || [ -n "$font_name" ]; do
    case "$font_name" in ''|'#'*) continue ;; esac
    case "$font_name" in
      *[!A-Za-z0-9_-]*|[-_]*) log_error "Invalid font archive name: $font_name"; exit 1 ;;
    esac
    target="$FONT_DIR/$font_name"
    if [ -f "$target/.version" ] && [ "$(cat "$target/.version")" = "$FONT_VERSION" ] &&
        [ -n "$(find "$target" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit)" ]; then
      log_info "Keeping $font_name $FONT_VERSION"
      continue
    fi
    archive="$temporary_dir/$font_name.tar.xz"
    stage="$temporary_dir/$font_name"
    mkdir -p "$stage"
    curl --fail --location --retry 3 --output "$archive" \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$font_name.tar.xz"
    tar -xJf "$archive" -C "$stage" --no-same-owner
    if [ -z "$(find "$stage" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit)" ]; then
      log_error "No fonts found in $font_name archive"
      exit 1
    fi
    # Copy into this installer's font family directory after successful extraction.
    mkdir -p "$target"
    cp -R "$stage/." "$target/"
    printf '%s\n' "$FONT_VERSION" > "$target/.version"
    changed=true
    log_success "Installed $font_name $FONT_VERSION"
  done < "$MANIFEST"

  if [ "$changed" = true ] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR"
  fi
}

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"

  if [ "$(uname -s)" = Linux ] && [ -r /etc/os-release ]; then
    ID= ID_LIKE=
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
      *' arch '*)
        log_info 'Nerd Fonts are managed by pacman on Arch; run bootstrap packages to install them'
        return 0 ;;
    esac
  fi

  configure_fonts
  install_fonts
}

main "$@"
