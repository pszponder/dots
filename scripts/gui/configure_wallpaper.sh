#!/bin/sh
set -eu

configure_gnome() {
  command -v gsettings >/dev/null 2>&1 || { log_error 'GNOME requires gsettings'; return 1; }
  uri=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$WALLPAPER")
  gsettings set org.gnome.desktop.background picture-uri "$uri"
  keys=$(gsettings list-keys org.gnome.desktop.background)
  if printf '%s\n' "$keys" | grep -q '^picture-uri-dark$'; then
    gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
  fi
  gsettings set org.gnome.desktop.background picture-options zoom
}

configure_cosmic() {
  # COSMIC watches these v1 RON files; same-on-all overrides per-output entries.
  # Schema: https://github.com/pop-os/cosmic-bg/blob/master/config/src/lib.rs
  python3 - "$WALLPAPER" <<'PY'
import json
import os
from pathlib import Path
import sys

config = Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config')
config /= 'cosmic/com.system76.CosmicBackground/v1'
config.mkdir(parents=True, exist_ok=True)
source = json.dumps(str(Path(sys.argv[1]).resolve()), ensure_ascii=False)
values = {
    'all': f'(output: "all", source: Path({source}), filter_by_theme: false, rotation_frequency: 900, scaling_mode: Zoom)',
    'same-on-all': 'true',
}
for name, value in values.items():
    target = config / name
    text = value + '\n'
    if target.exists() and target.read_text() == text:
        continue
    if target.exists():
        backup = config / (name + '.before-dotfiles')
        if not backup.exists():
            backup.write_bytes(target.read_bytes())
    target.write_text(text)
PY
}

configure_omarchy() {
  omarchy theme bg set "$WALLPAPER"
}

main() {
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  . "$SCRIPT_DIR/../utils/utils_logging.sh"
  [ "$(uname -s)" = Linux ] || return 0
  if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    log_warn 'No graphical session; rerun sh scripts/gui/configure_wallpaper.sh after logging into your desktop'
    return 0
  fi

  desktop=$(printf '%s' "${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')
  case "$desktop" in
    *cosmic*) backend=cosmic ;;
    *gnome*) backend=gnome ;;
    *hyprland*)
      if command -v omarchy >/dev/null 2>&1; then
        backend=omarchy
      else
        log_warn 'Hyprland without Omarchy is not supported; skipping wallpaper'
        return 0
      fi ;;
    *) log_warn "Unsupported desktop: $desktop; skipping wallpaper"; return 0 ;;
  esac

  WALLPAPER="$HOME/Pictures/wallpapers/catppuccin-mocha.png"
  [ -f "$WALLPAPER" ] || { log_error "Wallpaper missing: $WALLPAPER (apply dotfiles first)"; return 1; }
  if [ "$backend" != omarchy ]; then
    command -v python3 >/dev/null 2>&1 || { log_error 'Wallpaper configuration requires python3'; return 1; }
  fi
  "configure_$backend"
  log_success "Configured $backend wallpaper"
}

main "$@"
