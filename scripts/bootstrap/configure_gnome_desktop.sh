#!/bin/sh
# Apply Ubuntu GNOME preferences in the logged-in user's desktop session.
set -eu

case ":${XDG_CURRENT_DESKTOP:-}:" in
  *:GNOME:*|*:gnome:*) ;;
  *) printf 'Skipping desktop setup: run setup:gnome:desktop from a GNOME session.\n'; exit 0 ;;
esac
if [ "$(id -u)" = 0 ]; then
  printf 'Run desktop setup as your login user, not root.\n' >&2
  exit 1
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  printf 'Skipping desktop setup: no desktop session bus. Run setup:gnome:desktop after logging in.\n'
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
interface_keys=$(gsettings list-keys org.gnome.desktop.interface)
if printf '%s\n' "$interface_keys" | grep -qx accent-color; then
  gsettings set org.gnome.desktop.interface accent-color 'purple'
else
  printf 'Skipping accent color: this GNOME version does not support it.\n'
fi
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# Saved Ubuntu Dock preferences; leave unrelated extension settings alone.
if gsettings list-schemas | grep -qx org.gnome.shell.extensions.dash-to-dock; then
  dock_schema=org.gnome.shell.extensions.dash-to-dock
  # Release numbered app shortcuts and the dock overlay shortcut (Super+Q).
  gsettings set "$dock_schema" hot-keys false
  gsettings set "$dock_schema" shortcut "[]"
  gsettings set "$dock_schema" dock-fixed false
  gsettings set "$dock_schema" dock-position 'BOTTOM'
  gsettings set "$dock_schema" extend-height false
  gsettings set "$dock_schema" show-mounts-network true
  gsettings set "$dock_schema" show-mounts-only-mounted true
else
  printf 'Skipping Ubuntu Dock preferences: extension schema is not installed.\n'
fi
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'zen.desktop', 'helium.desktop', 'code_code.desktop', 'ghostty_ghostty.desktop', 'obsidian_obsidian.desktop', 'discord_discord.desktop']"
# GNOME shortcuts; half-screen snapping uses Ubuntu Tiling Assistant.
wm_schema=org.gnome.desktop.wm.keybindings
media_schema=org.gnome.settings-daemon.plugins.media-keys
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 9
for number in 1 2 3 4 5 6 7 8 9; do
  gsettings set org.gnome.shell.keybindings "switch-to-application-$number" "[]"
  gsettings set "$wm_schema" "switch-to-workspace-$number" "['<Super>$number']"
  gsettings set "$wm_schema" "move-to-workspace-$number" "['<Super><Shift>$number']"
done
# Release Super+H from minimizing; keep Alt+F9 for minimize.
gsettings set "$wm_schema" minimize "['<Super><Shift>j', '<Alt>F9']"
# H/L cycle windows in recent-use order, rather than spatially.
gsettings set "$wm_schema" switch-windows "['<Super>l']"
gsettings set "$wm_schema" switch-windows-backward "['<Super>h']"
# Alt+Tab cycles applications in recent-use order across all workspaces.
gsettings set org.gnome.shell.app-switcher current-workspace-only false
gsettings set "$wm_schema" switch-applications "['<Super>Tab', '<Alt>Tab']"
gsettings set "$wm_schema" switch-applications-backward "['<Shift><Super>Tab', '<Shift><Alt>Tab']"
# Release the old edge-positioning bindings before assigning half-screen snaps.
for side in n w s e; do
  gsettings set "$wm_schema" "move-to-side-$side" "[]"
done
if gsettings list-schemas | grep -qx org.gnome.shell.extensions.tiling-assistant; then
  tiling_schema=org.gnome.shell.extensions.tiling-assistant
  gsettings set "$tiling_schema" tile-left-half "['<Super><Shift>h', '<Super>Left', '<Super>KP_4']"
  gsettings set "$tiling_schema" tile-bottom-half "['<Super>KP_2']"
  gsettings set "$tiling_schema" tile-top-half "['<Super>KP_8']"
  gsettings set "$tiling_schema" tile-right-half "['<Super><Shift>l', '<Super>Right', '<Super>KP_6']"
else
  printf 'Skipping half-screen shortcuts: install and enable GNOME Tiling Assistant.\n'
fi
gsettings set "$wm_schema" close "['<Super>q', '<Alt>F4']"
gsettings set "$wm_schema" maximize "['<Super><Shift>k']"
gsettings set "$wm_schema" toggle-maximized "['<Super>m', '<Alt>F10']"
# Keep keyboard access to locking and notifications after freeing Super+L/M.
gsettings set "$media_schema" screensaver "['<Super><Control>l']"
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']"
gsettings set "$media_schema" terminal "['<Super>Return', '<Primary><Alt>t']"
gsettings set "$media_schema" www "['<Super><Shift>Return']"
gsettings set "$media_schema" home "['<Super>f', '<Super>e']"
printf 'GNOME desktop preferences configured.\n'
