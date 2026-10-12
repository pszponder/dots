# Only continue if the shell is interactive
# (env vars are sourced from ~/.zshenv, which runs for non-interactive shells too)
[[ $- != *i* ]] && return

# 🧩 Source aliases
if [[ -f ~/.config/aliases ]]; then
  source ~/.config/aliases
fi

# Shared shell functions.
if [[ -f ~/.config/shell/functions.sh ]]; then
  source ~/.config/shell/functions.sh
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if missing, but do not block shell startup on network issues.
# A failed attempt is throttled via a sentinel timestamp so an offline machine
# doesn't eat a 5s `git clone` stall on every single new shell.
if [[ ! -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  _zinit_lastfail_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zinit-clone-lastfail"
  mkdir -p "$(dirname "$ZINIT_HOME")" "$(dirname "$_zinit_lastfail_file")"
  _zinit_lastfail_ts="$(<"$_zinit_lastfail_file" 2>/dev/null)"
  _zinit_now="$(date +%s)"
  if command -v git &> /dev/null && (( _zinit_now - ${_zinit_lastfail_ts:-0} > 3600 )); then
    if ! timeout 5s git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" &>/dev/null; then
      print -r -- "$_zinit_now" >| "$_zinit_lastfail_file"
    fi
  fi
  unset _zinit_lastfail_file _zinit_lastfail_ts _zinit_now
fi

# Source zinit if available; otherwise keep shell startup working with no-op
# fallbacks so init below doesn't fail hard.
if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
else
  zinit() { :; }
  zsh-defer() { "$@"; }
fi

# Add in zsh plugins
# zsh-completions must load before compinit (it only adds to fpath)
zinit light zsh-users/zsh-completions

# Tiny helper used below to defer atuin/mise init until after the first prompt
zinit light romkatv/zsh-defer

# ⚡ Cache generated init scripts (fzf/starship/atuin/mise) instead of
# spawning their binary on every shell start. Invalidated by version, not
# mtime, since Nix normalizes store file mtimes and would otherwise never
# invalidate.
_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_zsh_cache_dir"

_cache_init() {
  local name=$1 version_cmd=$2 init_cmd=$3
  local cache_file="$_zsh_cache_dir/${name}-init.zsh"
  local version_file="$_zsh_cache_dir/${name}-version"
  local tmp_file="${cache_file}.tmp.$$"
  local current_version
  current_version="$(eval "$version_cmd" 2>/dev/null)"

  if [[ ! -s "$cache_file" || "$current_version" != "$(<"$version_file" 2>/dev/null)" ]]; then
    if eval "$init_cmd" >| "$tmp_file"; then
      command mv -f "$tmp_file" "$cache_file"
      print -r -- "$current_version" >| "$version_file"
    else
      rm -f "$tmp_file"
    fi
  fi
  [[ -s "$cache_file" ]] && source "$cache_file"
}

# fzf ctrl-t (insert file path) / alt-c (cd into dir) widgets. FZF_* env vars
# live in ~/.config/env.sh (shared with bash). ctrl-r is left to atuin
# (rebound below), and this must load before zsh-vi-mode since that plugin
# wipes all keybindings on init — the widgets themselves persist (defined via
# `zle -N`), only the bindings need reattaching in the hook.
if command -v fzf &> /dev/null; then
  _cache_init fzf "fzf --version" "fzf --zsh"
fi

# Per-command fzf preview: cd/z get an eza tree, ssh gets a dig lookup,
# everything else falls back to FZF_CTRL_T_OPTS' bat preview.
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

# zsh-vi-mode: replaces plain `bindkey -v` with cursor-shape switching per
# mode, text objects, and surround. Must load before the zvm_after_init hook
# below (it rebinds everything on init, so custom binds attach via the hook).
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none
zvm_after_init() {
  # Reattach bindings zsh-vi-mode wiped on init
  bindkey '^T' fzf-file-widget
  bindkey '\ec' fzf-cd-widget

  # At startup atuin may not be loaded yet (deferred), so keep Ctrl-R valid.
  if (( $+widgets[_atuin_search_widget] )); then
    bindkey '^R' _atuin_search_widget
  else
    bindkey '^R' history-incremental-search-backward
  fi
}

_bind_atuin_ctrl_r() {
  (( $+widgets[_atuin_search_widget] )) && bindkey '^R' _atuin_search_widget
}

zinit light jeffreytse/zsh-vi-mode

# Add in snippets / Plugins from Oh My Zsh
# https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
# zinit snippet OMZL::git.zsh
# zinit snippet OMZP::git
zinit snippet OMZP::sudo
# zinit snippet OMZP::archlinux
# zinit snippet OMZP::aws
# zinit snippet OMZP::kubectl
# zinit snippet OMZP::kubectx
# zinit snippet OMZP::docker
# zinit snippet OMZP::terraform
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::golang
# zinit snippet OMZP::python
# zinit snippet OMZP::uv
# zinit snippet OMZP::rust
# zinit snippet OMZP::tmux

# 🌟 Starship prompt (kept synchronous — deferring it causes a visible flash
# of the default prompt before the styled one loads)
if command -v starship &> /dev/null; then
  _cache_init starship "starship --version" "starship init zsh"
fi

# Atuin (Magical Shell History)
if command -v atuin &> /dev/null; then
  _cache_init atuin "atuin --version" "atuin init zsh"
  _bind_atuin_ctrl_r
fi

# 🧠 Mise (tool version manager)
if command -v mise &> /dev/null; then
  _cache_init mise "mise --version" "mise activate zsh"
fi

# 🔄 History control
_zsh_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$_zsh_state_dir"
HISTFILE="$_zsh_state_dir/history"
HISTSIZE=32768
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt APPEND_HISTORY              # Append to the history file, don't overwrite it
setopt INC_APPEND_HISTORY          # Write to history immediately, not on shell exit
setopt SHARE_HISTORY               # Share command history data
setopt HIST_IGNORE_SPACE           # Ignore commands that start with space
setopt HIST_IGNORE_DUPS            # Ignore duplicate entries
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS          # Remove superfluous blanks
setopt HIST_VERIFY                 # Don't execute when recalled from history
setopt EXTENDED_HISTORY            # Record command timestamp

# 🐚 Shell behavior
setopt AUTOCD                      # Typing a bare directory path cd's into it
setopt NUMERIC_GLOB_SORT           # Sort file10 after file9, not after file1

# ✨ Completions
# Only run the full (slow) security check once a day; use the cache otherwise
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -i
else
  compinit -C -i
fi

# Jujutsu dynamic completions (bookmarks, revisions, files, etc.).
if command -v jj &> /dev/null; then
  source <(COMPLETE=zsh jj)
fi

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Remaining zsh plugins
# fzf-tab must load after compinit; zsh-syntax-highlighting must load last (it wraps widgets)
zinit light zsh-users/zsh-autosuggestions

zinit light Aloxaf/fzf-tab

zinit light zsh-users/zsh-syntax-highlighting

# ✨ Prompt title in terminals like xterm
precmd() {
  print -Pn "\e]0;%n@%m: %~\a"
}

# Warpify subshells only when launched from Warp (and not inside tmux); use ESC backslash terminator
if [[ $TERM_PROGRAM == "WarpTerminal" && -z $TMUX ]]; then
  printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\e\\'
fi

# 🚀 Zoxide (better cd) — keep synchronous so `z` is available immediately
if command -v zoxide &> /dev/null; then
  _cache_init zoxide "zoxide --version" "zoxide init zsh"
fi

# Activate the default environment as recommended by Flox.
if command -v flox >/dev/null 2>&1; then
  eval "$(flox activate -D -m run)"
fi
