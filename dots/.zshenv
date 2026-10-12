export ZDOTDIR="$HOME/.config/zsh"

# .zshenv is sourced for EVERY zsh (login, interactive, non-interactive, and
# scripts), so it's the correct home for environment variables that must exist
# everywhere - unlike ~/.config/zsh/.zshrc, which returns early for
# non-interactive shells (ssh host cmd, `zsh -c`, cron).
[ -f "$HOME/.config/env.sh" ] && . "$HOME/.config/env.sh"

# Prevent stale Zsh command hashes from bypassing mise-managed executables.
unsetopt HASH_CMDS

# Keep PATH entries unique when multiple startup files prepend directories.
typeset -U path PATH

# Common user script/tool locations should be available in all shell modes.
# mise's shims dir is included here (not just via `mise activate`) so tools
# like starship/zoxide/atuin resolve synchronously on the very first prompt —
# `mise activate` itself is deferred in .zshrc and only runs after the first
# idle cycle, so `command -v <tool>` guards would otherwise fail on a fresh shell.
for dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/scripts" "/usr/local/bin" "$HOME/.local/share/mise/shims"; do
	[[ -d "$dir" ]] && PATH="$dir:$PATH"
done
unset dir

# Some terminals can start zsh with rc files disabled (`zsh -f` / `setopt norcs`).
# In that case, force-load .zshrc for interactive shells so prompt/plugins still
# initialize on first launch.
if [[ $- == *i* && ! -o rcs && -f "${ZDOTDIR:-$HOME}/.zshrc" ]]; then
	source "${ZDOTDIR:-$HOME}/.zshrc"
fi
