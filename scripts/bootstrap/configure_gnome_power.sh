#!/bin/sh
# Apply Ubuntu GNOME power and Night Light preferences for the login user.
set -eu

case ":${XDG_CURRENT_DESKTOP:-}:" in
  *:GNOME:*|*:gnome:*) ;;
  *) printf 'Skipping power setup: run setup:gnome:power from a GNOME session.\n'; exit 0 ;;
esac
if [ "$(id -u)" = 0 ]; then
  printf 'Run power setup as your login user, not root.\n' >&2
  exit 1
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  printf 'Skipping power setup: run setup:gnome:power after logging into the desktop.\n'
  exit 0
fi
for tool in gsettings powerprofilesctl; do
  command -v "$tool" >/dev/null || {
    printf 'Power setup requires %s. Install it and rerun setup:gnome:power.\n' "$tool" >&2
    exit 1
  }
done

# Check service access before writing desktop preferences.
powerprofilesctl get >/dev/null
gsettings set org.gnome.desktop.interface show-battery-percentage true
power_schema=org.gnome.settings-daemon.plugins.power
gsettings set "$power_schema" sleep-inactive-ac-timeout 1800
gsettings set "$power_schema" sleep-inactive-ac-type suspend
gsettings set "$power_schema" idle-dim true
# This key is unavailable on older GNOME releases.
if gsettings list-keys "$power_schema" | grep -qx power-saver-profile-on-low-battery; then
  gsettings set "$power_schema" power-saver-profile-on-low-battery true
else
  printf 'Skipping automatic power saver: this GNOME version does not support it.\n'
fi
color_schema=org.gnome.settings-daemon.plugins.color
gsettings set "$color_schema" night-light-schedule-automatic true
gsettings set "$color_schema" night-light-enabled true
powerprofilesctl set power-saver
printf 'GNOME power preferences configured; Night Light follows sunset to sunrise.\n'
