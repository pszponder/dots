# Shared shell functions.
#

# Keep indexed-array expressions below zero-based in both shells.
if [[ -n $ZSH_VERSION ]]; then
  setopt ksharrays
fi

# Compression
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
decompress() { tar -xzf "$@"; }

# Format an entire drive as one exFAT partition.
format-drive() {
  if (( $# != 2 )); then
    echo "Usage: format-drive <device> <name>"
    echo -e "\nAvailable drives:"
    lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
    return 1
  fi
  echo "WARNING: This will completely erase all data on $1 and label it '$2'."
  printf "Are you sure you want to continue? (y/N): "
  read -r confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
    sudo wipefs -a "$1"
    sudo dd if=/dev/zero of="$1" bs=1M count=100 status=progress
    sudo parted -s "$1" mklabel gpt
    sudo parted -s "$1" mkpart primary 1MiB 100%
    sudo parted -s "$1" set 1 msftdata on
    local partition
    if [[ $1 == *nvme* ]]; then partition="${1}p1"; else partition="${1}1"; fi
    sudo partprobe "$1" || true
    sudo udevadm settle || true
    sudo mkfs.exfat -n "$2" "$partition"
    echo "Drive $1 formatted as exFAT and labeled '$2'."
  fi
}



# Tmux development layouts
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <agent> [<second_agent>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }
  local dir="$PWD" editor="$TMUX_PANE" ai="$1" ai2="${2:-}" right second
  tmux rename-window -t "$editor" "$(basename "$dir")"
  tmux split-window -v -p 15 -t "$editor" -c "$dir"
  right="$(tmux split-window -h -p 30 -t "$editor" -c "$dir" -P -F '#{pane_id}')"
  if [[ -n $ai2 ]]; then
    second="$(tmux split-window -v -t "$right" -c "$dir" -P -F '#{pane_id}')"
    tmux send-keys -t "$second" "$ai2" C-m
  fi
  tmux send-keys -t "$right" "$ai" C-m
  tmux send-keys -t "$editor" "$EDITOR ." C-m
  tmux select-pane -t "$editor"
}

tds() {
  [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }
  local dir="$PWD" editor="$TMUX_PANE" terminal diff agent
  tmux rename-window -t "$editor" "$(basename "$dir")"
  terminal="$(tmux split-window -v -p 50 -t "$editor" -c "$dir" -P -F '#{pane_id}')"
  diff="$(tmux split-window -h -p 50 -t "$editor" -c "$dir" -P -F '#{pane_id}')"
  agent="$(tmux split-window -h -p 50 -t "$terminal" -c "$dir" -P -F '#{pane_id}')"
  tmux send-keys -t "$editor" "nvim ." C-m
  tmux send-keys -t "$diff" "hunk diff --watch" C-m
  tmux send-keys -t "$agent" "opencode" C-m
  tmux select-pane -t "$editor"
}

tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <agent> [<second_agent>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }
  local ai="$1" ai2="${2:-}" base="$PWD" first=true dir pane command
  tmux rename-session "$(basename "$base" | tr '.:' '--')"
  for dir in "$base"/*/; do
    [[ -d $dir ]] || continue
    dir="${dir%/}"
    command="cd $(printf '%q' "$dir") && tdl $(printf '%q' "$ai")"
    [[ -n $ai2 ]] && command="$command $(printf '%q' "$ai2")"
    if $first; then
      tmux send-keys -t "$TMUX_PANE" "$command" C-m
      first=false
    else
      pane="$(tmux new-window -c "$dir" -P -F '#{pane_id}')"
      tmux send-keys -t "$pane" "$command" C-m
    fi
  done
}

tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }
  local count="$1" command="$2" dir="$PWD" pane new_pane
  local -a panes
  tmux rename-window -t "$TMUX_PANE" "$(basename "$dir")"
  panes=("$TMUX_PANE")
  while (( ${#panes[@]} < count )); do
    pane="${panes[${#panes[@]}-1]}"
    new_pane="$(tmux split-window -h -t "$pane" -c "$dir" -P -F '#{pane_id}')"
    panes+=("$new_pane")
    tmux select-layout -t "${panes[0]}" tiled
  done
  for pane in "${panes[@]}"; do tmux send-keys -t "$pane" "$command" C-m; done
  tmux select-pane -t "${panes[0]}"
}

# Herdr development layouts
_herdr_ratio() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a / b }'; }
_herdr_split() {
  herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus |
    jq -r '.result.pane.pane_id'
}
hdl() {
  [[ -z $1 ]] && { echo "Usage: hdl <agent> [<second_agent>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdl."; return 1; }
  local dir="$PWD" editor="$HERDR_PANE_ID" ai="$1" ai2="${2:-}" right second
  herdr tab rename "$HERDR_TAB_ID" "$(basename "$dir")" >/dev/null
  _herdr_split "$editor" down 0.85 "$dir" >/dev/null
  right="$(_herdr_split "$editor" right 0.7 "$dir")"
  if [[ -n $ai2 ]]; then
    second="$(_herdr_split "$right" down 0.5 "$dir")"
    herdr pane run "$second" "$ai2" >/dev/null
  fi
  herdr pane run "$right" "$ai" >/dev/null
  herdr pane run "$editor" "$EDITOR ." >/dev/null
}
hds() {
  [[ -n $1 ]] && { echo "Usage: hds"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hds."; return 1; }
  local dir="$PWD" editor="$HERDR_PANE_ID" terminal diff agent
  herdr tab rename "$HERDR_TAB_ID" "$(basename "$dir")" >/dev/null
  terminal="$(_herdr_split "$editor" down 0.5 "$dir")"
  diff="$(_herdr_split "$editor" right 0.5 "$dir")"
  agent="$(_herdr_split "$terminal" right 0.5 "$dir")"
  herdr pane run "$editor" "nvim ." >/dev/null
  herdr pane run "$diff" "hunk diff --watch" >/dev/null
  herdr pane run "$agent" "opencode" >/dev/null
}
hdlm() {
  [[ -z $1 ]] && { echo "Usage: hdlm <agent> [<second_agent>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdlm."; return 1; }
  local ai="$1" ai2="${2:-}" base="$PWD" first=true dir path pane command
  herdr workspace rename "$HERDR_WORKSPACE_ID" "$(basename "$base")" >/dev/null
  for dir in "$base"/*/; do
    [[ -d $dir ]] || continue
    path="${dir%/}"
    command="cd $(printf '%q' "$path") && hdl $(printf '%q' "$ai")"
    [[ -n $ai2 ]] && command="$command $(printf '%q' "$ai2")"
    if $first; then
      herdr pane run "$HERDR_PANE_ID" "$command" >/dev/null
      first=false
    else
      pane="$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$path" --no-focus | jq -r '.result.root_pane.pane_id')"
      herdr pane run "$pane" "$command" >/dev/null
    fi
  done
}
hsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: hsl <pane_count> <command>"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hsl."; return 1; }
  local count="$1" command="$2" dir="$PWD" cols=1 index rows j col last pane
  local -a columns panes
  herdr tab rename "$HERDR_TAB_ID" "$(basename "$dir")" >/dev/null
  while (( cols * cols < count )); do ((cols++)); done
  columns=("$HERDR_PANE_ID")
  for (( j=1; j<cols; j++ )); do
    columns+=("$(_herdr_split "${columns[${#columns[@]}-1]}" right "$(_herdr_ratio 1 $((cols-j+1)))" "$dir")")
  done
  for (( index=0; index<cols; index++ )); do
    col="${columns[index]}"; rows=$((count / cols)); (( index < count % cols )) && ((rows++))
    panes+=("$col"); last="$col"
    for (( j=1; j<rows; j++ )); do
      last="$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows-j+1)))" "$dir")"
      panes+=("$last")
    done
  done
  for pane in "${panes[@]}"; do herdr pane run "$pane" "$command" >/dev/null; done
}

# Git worktrees (renamed to avoid the existing ga/gd aliases).
gwt() {
  [[ -z $1 ]] && { echo "Usage: gwt <branch name>"; return 1; }
  local branch="$1" base path
  base="$(basename "$PWD")"; path="../${base}--${branch}"
  git worktree add -b "$branch" "$path" || return 1
  command -v mise >/dev/null 2>&1 && mise trust "$path"
  cd "$path" || return 1
}
gwd() {
  if command -v gum >/dev/null 2>&1 && gum confirm "Remove worktree and branch?"; then
    local cwd base root branch
    cwd="$PWD"; base="$(basename "$cwd")"; root="${base%%--*}"; branch="${base#*--}"
    [[ $root == "$base" ]] && return 0
    cd "../$root" || return 1
    git worktree remove "$cwd" --force || return 1
    git branch -D "$branch"
  else
    echo "gwd requires gum for confirmation" >&2
    return 1
  fi
}

# Rsync-on-change watchers
rsw() {
  (( $# != 2 )) && { echo "Usage: rsw <source> <destination>"; return 1; }
  local src="${1%/}" dest="$2" sockets="${XDG_RUNTIME_DIR:-$HOME/.ssh/sockets}" rsh
  mkdir -p "$sockets"
  rsh="ssh -o ControlMaster=auto -o ControlPath=$sockets/rsw-%r@%h:%p -o ControlPersist=yes"
  setsid --fork env RSYNC_RSH="$rsh" bash -c 'rsync -a "$1/" "$2"; while inotifywait -r -q -e modify,create,delete,move "$1"; do rsync -a "$1/" "$2"; done' rsw-watch "$src" "$dest" >/dev/null 2>&1
  echo "Watching $src -> $dest"
}
lsw() {
  local pid cmd rest found=0
  while read -r pid cmd; do rest="${cmd##*rsw-watch }"; echo "$pid: ${rest% *} -> ${rest##* }"; found=1; done < <(pgrep -af 'rsw-watch ')
  (( found )) || echo "No active watches"
}
dsw() {
  local pid found=0
  for pid in $(pgrep -f 'rsw-watch '); do kill -- -"$pid" 2>/dev/null && echo "Stopped watch (pid $pid)" && found=1; done
  (( found )) || echo "No active watches"
}

# SSH port forwarding
fip() { (( $# < 2 )) && { echo "Usage: fip <host> <port1> [port2] ..."; return 1; }; local host="$1" port; shift; for port in "$@"; do ssh -f -N -L "${port}:localhost:${port}" "$host" && echo "Forwarding localhost:$port -> $host:$port"; done; }
dip() { (( $# == 0 )) && { echo "Usage: dip <port1> [port2] ..."; return 1; }; local port; for port in "$@"; do pkill -f "ssh.*-L ${port}:localhost:${port}" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"; done; }
lip() { pgrep -af 'ssh.*-L [0-9]+:localhost:[0-9]+' || echo "No active forwards"; }

# Reconnect interactive SSH sessions after a transport failure.
ssh() {
  local rc started=$SECONDS
  command ssh "$@"; rc=$?
  [[ -t 1 ]] || return $rc
  _ssh_disarm
  if (( rc != 255 )) || [[ ! -t 0 ]] || ! _ssh_interactive "$@" || (( SECONDS - started < 30 )); then return $rc; fi
  (
    while true; do
      echo "Connection lost. Reconnecting (Ctrl-C to stop)..."; sleep 2
      command ssh "$@"; rc=$?; _ssh_disarm; (( rc != 255 )) && exit $rc
    done
  )
}
_ssh_disarm() { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'; }
_ssh_interactive() {
  local value_opts='BbcDEeFIiJLlmOoPpQRSWw' arg letters i dest='' opts_done='' argv=("$@")
  while (($#)); do
    arg="$1"; shift
    if [[ -z $opts_done && $arg == -- ]]; then opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for ((i=0; i<${#letters}; i++)); do
        if [[ $value_opts == *"${letters:i:1}"* ]]; then (( i == ${#letters}-1 )) && shift; break; fi
      done
    elif [[ -z $dest ]]; then dest="$arg"; else return 1; fi
  done
  [[ -n $dest ]] || return 1
  local resolved
  resolved="$(command ssh -G "${argv[@]}" 2>/dev/null)" || return 1
  ! grep -i '^remotecommand ' <<<"$resolved" | grep -qvi '^remotecommand none$'
}
