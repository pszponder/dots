#!/bin/sh
# Configure keyboard access after mise tools and dotfiles have been installed.
set -eu

if [ "$(uname -s)" != Linux ]; then
  printf 'Skipping Kanata device setup: Linux only.\n'
  exit 0
fi
if [ "$(id -u)" = 0 ]; then
  printf 'Run Kanata setup as your login user, not root.\n' >&2
  exit 1
fi

login_user=$(id -un)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
if [ ! -f "$config_dir/systemd/user/kanata.service" ] ||
   [ ! -f "$config_dir/kanata/kanata.kbd" ]; then
  printf 'Deploy Kanata dotfiles before running device setup.\n' >&2
  exit 1
fi

for group in input uinput; do
  if ! getent group "$group" >/dev/null; then
    sudo groupadd --system "$group"
  fi
done
sudo usermod -aG input,uinput "$login_user"

printf '%s\n' 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
  sudo tee /etc/udev/rules.d/99-kanata.rules >/dev/null
printf 'uinput\n' | sudo tee /etc/modules-load.d/kanata.conf >/dev/null
sudo modprobe uinput
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput

systemctl --user daemon-reload
systemctl --user enable kanata.service

# The running user manager retains its login-time supplementary groups.
current_groups=" $(id -nG) "
case "$current_groups" in
  *' input '*) ;;
  *) printf 'Kanata configured. Reboot to activate keyboard permissions and start the service.\n'; exit 0 ;;
esac
case "$current_groups" in
  *' uinput '*) ;;
  *) printf 'Kanata configured. Reboot to activate keyboard permissions and start the service.\n'; exit 0 ;;
esac
systemctl --user restart kanata.service
printf 'Kanata configured and service restarted.\n'
