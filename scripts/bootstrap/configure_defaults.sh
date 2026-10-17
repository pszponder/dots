#!/bin/sh
# Configure application defaults in the logged-in user's desktop session.
set -eu

terminal=${1:-}
browser=${2:-}
if [ -z "$terminal" ] || [ -z "$browser" ]; then
  printf 'Skipping application defaults: this workstation profile has no defaults configured.\n'
  exit 0
fi
if [ "$(id -u)" = 0 ]; then
  printf 'Run application defaults setup as your login user, not root.\n' >&2
  exit 1
fi
if [ -z "${XDG_CURRENT_DESKTOP:-}" ] || [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  printf 'Skipping application defaults: run setup:defaults after logging into the desktop.\n'
  exit 0
fi
for tool in xdg-settings xdg-mime xdg-terminal-exec; do
  command -v "$tool" >/dev/null || {
    printf 'Application defaults require %s. Install it and rerun setup:defaults.\n' "$tool" >&2
    exit 1
  }
done

# Check both applications before changing any settings. Snap exports may not yet
# be in XDG_DATA_DIRS when bootstrap installs the applications in this session.
for app in "$terminal" "$browser"; do
  case "$app" in
    */*|*[!a-zA-Z0-9._-]*|'' ) printf 'Invalid desktop entry ID: %s\n' "$app" >&2; exit 1 ;;
    *.desktop) ;;
    *) printf 'Expected a .desktop entry ID: %s\n' "$app" >&2; exit 1 ;;
  esac
  found=false
  old_ifs=$IFS
  IFS=:
  for directory in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS:-/usr/local/share:/usr/share} /var/lib/snapd/desktop; do
    if [ -f "$directory/applications/$app" ]; then
      found=true
      break
    fi
  done
  IFS=$old_ifs
  if [ "$found" = false ]; then
    printf 'Missing desktop entry %s. Install the application and rerun setup:defaults.\n' "$app" >&2
    exit 1
  fi
done

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
mkdir -p "$config_home"
# Keep other preferred terminals and launcher directives as fallbacks.
terminal_list="$config_home/xdg-terminals.list"
temporary=$(mktemp "$config_home/.xdg-terminals.XXXXXX")
trap 'rm -f "$temporary"' EXIT HUP INT TERM
printf '%s\n' "$terminal" > "$temporary"
if [ -f "$terminal_list" ]; then
  awk -v terminal="$terminal" '$0 != terminal' "$terminal_list" >> "$temporary"
fi
# The Ghostty Snap entry lacks TerminalArgExec; Ghostty runs commands with -e.
case "$terminal" in
  ghostty_ghostty.desktop)
    if ! grep -qx '/execarg_default:ghostty_ghostty.desktop:-e' "$temporary"; then
      printf '%s\n' '/execarg_default:ghostty_ghostty.desktop:-e' >> "$temporary"
    fi
    ;;
esac
mv "$temporary" "$terminal_list"

case ":$XDG_CURRENT_DESKTOP:" in
  *:GNOME:*|*:gnome:*)
    gsettings set org.gnome.desktop.default-applications.terminal exec xdg-terminal-exec
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg "'--'"
    ;;
esac
xdg-settings set default-web-browser "$browser"
for mime in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
  xdg-mime default "$browser" "$mime"
done
printf 'Application defaults configured: terminal=%s browser=%s\n' "$terminal" "$browser"
