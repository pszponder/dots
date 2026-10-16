# ~/.bashrc
#
# Bash equivalent of ~/.config/zsh/.zshrc — kept as close to feature parity as
# bash allows.

# Environment variables (EDITOR/PAGER/XDG/LANG/...): source BEFORE the
# interactive guard below so login shells and any shell that sources this file
# get them, not just interactive ones. (Bash has no always-sourced equivalent of
# zsh's ~/.zshenv; fully non-interactive `ssh host cmd` still needs BASH_ENV set
# to pick these up.)
[ -f "$HOME/.config/env.sh" ] && source "$HOME/.config/env.sh"

# Only continue if the shell is interactive
[[ $- != *i* ]] && return

# ✨ Update PATH with common user script/tool locations
# Include mise shims for commands that need them during shell startup.
for dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/scripts" "/usr/local/bin" "$HOME/.local/share/mise/shims"; do
  [[ ":$PATH:" != *":$dir:"* ]] && PATH="$dir:$PATH"
done
export PATH
unset dir # Clean up loop var

# 🧩 Source aliases
if [[ -f ~/.config/aliases ]]; then
  source ~/.config/aliases
fi

# Shared shell functions.
if [[ -f ~/.config/shell/functions.sh ]]; then
  source ~/.config/shell/functions.sh
fi

# VIM mode
set -o vi

# Prevent stale Bash command hashes from bypassing mise-managed executables.
set +h

# bash-completion (tab-complete for git, docker, etc. — zsh's compinit equivalent).
if [[ -n $BASH_VERSION ]]; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
  fi
fi

# 🔄 History control (set before starship/mise/zoxide below so they each chain
# onto PROMPT_COMMAND instead of one overwriting the others)
_bash_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/bash"
mkdir -p "$_bash_state_dir"
HISTFILE="$_bash_state_dir/history"
HISTSIZE=32768
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignoreboth:erasedups # ignore space-prefixed + dup commands, erase old dups
HISTTIMEFORMAT='%F %T '          # record command timestamp
shopt -s histappend              # append to history file, don't overwrite it
shopt -s cmdhist                 # save multi-line commands as one history entry
PROMPT_COMMAND='history -a'      # write to history file immediately, not on shell exit

# ✨ Prompt title in terminals like xterm
PROMPT_COMMAND="$PROMPT_COMMAND"'; printf "\e]0;%s@%s: %s\a" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'

# ⚡ Cache generated init scripts (starship/mise/zoxide) instead of
# spawning their binary on every shell start. Invalidated by version, not
# mtime, since Nix normalizes store file mtimes and would otherwise never
# invalidate. Namespaced with a "-bash" suffix since these commands emit
# different output per shell.
_bash_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bash"
mkdir -p "$_bash_cache_dir"

_cache_init() {
  local name=$1 version_cmd=$2 init_cmd=$3
  local cache_file="$_bash_cache_dir/${name}-init.bash"
  local version_file="$_bash_cache_dir/${name}-version"
  local tmp_file="${cache_file}.tmp.$$"
  local current_version
  current_version="$(eval "$version_cmd" 2>/dev/null)"

  if [[ ! -s "$cache_file" || "$current_version" != "$(cat "$version_file" 2>/dev/null)" ]]; then
    if eval "$init_cmd" > "$tmp_file"; then
      command mv -f "$tmp_file" "$cache_file"
      printf '%s' "$current_version" > "$version_file"
    else
      rm -f "$tmp_file"
    fi
  fi
  [[ -s "$cache_file" ]] && source "$cache_file"
}

# Activate mise before initializing any tools it manages.
# 🧠 Mise (tool version manager)
if command -v mise &> /dev/null; then
  _cache_init mise "mise --version" "mise activate bash"
fi

# Jujutsu dynamic completions (bookmarks, revisions, files, etc.).
if command -v jj &> /dev/null; then
  source <(COMPLETE=bash jj)
fi

# 🌟 Starship prompt
if command -v starship &> /dev/null; then
  _cache_init starship "starship --version" "starship init bash"
fi

# 🔍 fzf ctrl-t (insert file path) / alt-c (cd into dir) widgets. FZF_* env
# vars live in ~/.config/env.sh (shared with zsh). This must run before
# fzf's own ctrl-r binding is retained in Bash.
if command -v fzf &> /dev/null; then
  _cache_init fzf "fzf --version" "fzf --bash"
fi

# Per-command fzf preview: cd/z get an eza tree, ssh gets a dig lookup,
# everything else falls back to FZF_CTRL_T_OPTS' bat preview. (Parity with
# the same function in .zshrc — fzf's completion.bash honors it too.)
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd|z)         fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "bat --color=always --style=plain,numbers --line-range=:500 {}" "$@" ;;
  esac
}

# 🚀 Zoxide (better cd)
if command -v zoxide &> /dev/null; then
  _cache_init zoxide "zoxide --version" "zoxide init bash"
fi

# Warpify subshells only when launched from Warp (and not inside tmux); use ESC backslash terminator
if [[ $TERM_PROGRAM == "WarpTerminal" && -z $TMUX ]]; then
  printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "bash"}}\e\\'
fi

# End of interactive Bash configuration.

# Activate the default environment as recommended by Flox.
if command -v flox >/dev/null 2>&1; then
  eval "$(flox activate -D -m run)"
fi
