#!/bin/sh
# Apply Ubuntu GNOME preferences in the logged-in user's desktop session.
set -eu

case ":${XDG_CURRENT_DESKTOP:-}:" in
  *:GNOME:*|*:gnome:*) ;;
  *) printf 'Skipping desktop setup: run setup:desktop from a GNOME session.\n'; exit 0 ;;
esac
if [ "$(id -u)" = 0 ]; then
  printf 'Run desktop setup as your login user, not root.\n' >&2
  exit 1
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  printf 'Skipping desktop setup: no desktop session bus. Run setup:desktop after logging in.\n'
  exit 0
fi
command -v gsettings >/dev/null
wallpaper="$HOME/Pictures/wallpapers/catppuccin-mocha.png"
if [ ! -f "$wallpaper" ]; then
  printf 'Deploy dotfiles before running desktop setup: missing %s\n' "$wallpaper" >&2
  exit 1
fi
# Encode spaces and other special characters in the home directory as a file URI.
wallpaper_uri=$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$wallpaper")
keys=$(gsettings list-keys org.gnome.desktop.background)
gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
if printf '%s\n' "$keys" | grep -qx picture-uri-dark; then
  gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
fi
gsettings set org.gnome.desktop.background picture-options zoom
gsettings set org.gnome.desktop.interface accent-color 'purple'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# Saved Ubuntu Dock preferences; leave unrelated extension settings alone.
if gsettings list-schemas | grep -qx org.gnome.shell.extensions.dash-to-dock; then
  dock_schema=org.gnome.shell.extensions.dash-to-dock
  gsettings set "$dock_schema" dock-fixed false
  gsettings set "$dock_schema" dock-position 'BOTTOM'
  gsettings set "$dock_schema" extend-height false
  gsettings set "$dock_schema" show-mounts-network true
  gsettings set "$dock_schema" show-mounts-only-mounted true
else
  printf 'Skipping Ubuntu Dock preferences: extension schema is not installed.\n'
fi
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'zen.desktop', 'helium.desktop', 'code_code.desktop', 'ghostty_ghostty.desktop', 'obsidian_obsidian.desktop', 'discord_discord.desktop']"
printf 'GNOME desktop preferences configured.\n'
