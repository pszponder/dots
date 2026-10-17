#!/bin/sh
set -eu
config=${XDG_CONFIG_HOME:-$HOME/.config}/git
mkdir -p "$config"
# Git reads XDG config before ~/.gitconfig. Both local files override defaults.
target=$config/config
[ ! -L "$target" ] || { printf 'Refusing to edit symlinked Git config: %s\n' "$target" >&2; exit 1; }
if [ -f "$target" ] && git config --file "$target" --get-all include.path | grep -Fx "$config/defaults" >/dev/null; then exit 0; fi
temporary=$(mktemp "$config/.git-config.XXXXXX")
trap 'rm -f -- "$temporary"' EXIT HUP INT TERM
# Defaults first, existing machine settings last.
git config --file "$temporary" --add include.path "$config/dotfiles-identity"
git config --file "$temporary" --add include.path "$config/defaults"
[ ! -f "$target" ] || cat "$target" >> "$temporary"
cat "$temporary" > "$target"
