# Tmux and Herdr bindings

This guide describes the original configs in `dots/.config/tmux/tmux.conf`
and `dots/.config/herdr/config.toml`. Herdr tabs correspond to tmux windows;
workspaces correspond to sessions.

Tmux accepts **Ctrl-Space** or **Ctrl-b** as its prefix. Herdr uses **Ctrl-b**.
For a prefixed binding, press and release the prefix, then press the key.
Direct shortcuts work without a prefix. Capital letters mean Shift plus the letter.

## Shared bindings

| Key after prefix | Action |
| --- | --- |
| `?` | Show bindings/help |
| `q` | Reload configuration |
| `d` | Detach |
| `h` or `"` | Split into top/bottom panes |
| `v` or `%` | Split into left/right panes |
| Arrow | Focus pane in that direction |
| `x` | Close pane |
| `z` | Toggle pane zoom |
| `;` | Return to last pane |
| `[` | Enter copy mode |
| `c` | New window/tab in the active pane's directory |
| `r` or `,` | Rename window/tab |
| `k` or `&` | Close window/tab |
| `1` through `9` | Select window/tab |
| `p` / `n` | Previous/next window/tab |
| `C` | New session/workspace |
| `R` or `$` | Rename session in tmux; only `R` renames workspace in Herdr |
| `K` | Close session/workspace |
| `P` / `N` | Previous/next session/workspace |
| `s` / `w` | Session/window tree in tmux; workspace picker in Herdr |

Stock tmux bindings remain available unless explicitly overridden. For example,
`"`, `%`, `,`, and `&` are stock aliases; the config adds `h`, `v`, `r`, and `k`.

| Direct shortcut | Action in both |
| --- | --- |
| Alt-Enter | Split into top/bottom panes |
| Alt-Shift-Enter | Split into left/right panes |
| Alt-Escape | Close pane |
| Ctrl-Alt-arrow | Focus pane in that direction |
| Ctrl-Alt-Shift-arrow | Resize pane in that direction |
| Alt-1 through Alt-9 | Select window/tab |
| Alt-Left / Alt-Right | Previous/next window/tab |
| Alt-Shift-Left / Alt-Shift-Right | Move window/tab left/right |
| Alt-Up / Alt-Down | Previous/next session/workspace |

## Navigation and copy mode

Pane navigation uses arrows, either after the prefix or with Ctrl-Alt.
**Prefix+h splits a pane; it does not focus left.** These configs do not use
prefixed `hjkl` pane navigation.

Tmux uses vi copy mode: `h/j/k/l` move within scrollback, `v` begins selection,
`y` copies and exits, and `q` exits. Prefix+`]` pastes the tmux buffer.
Herdr also uses `v` and `y` in its own copy mode and additionally accepts
prefix+`y` to enter it. The applications have separate clipboard behavior.

Prefix+Ctrl-arrow resizes a pane directly in tmux. In Herdr, it enters resize
mode instead. The direct Ctrl-Alt-Shift-arrow bindings resize in both apps;
tmux uses five-cell increments for these direct shortcuts.

## Overrides of stock tmux behavior

| Setting or binding | Stock tmux | This config |
| --- | --- | --- |
| Primary prefix | Ctrl-b | Ctrl-Space, with Ctrl-b as secondary |
| Prefix+`q` | Display pane numbers | Reload config |
| Prefix+`r` | Refresh client | Rename window |
| Prefix+`x` | Confirm before closing pane | Close pane immediately |
| Prefix+`c` | New window | New window in active pane's directory |
| Prefix+`C` | Customize options | New session in active pane's directory |
| Prefix+`?` | List keys with notes | List full key bindings |
| Copy mode | Default Emacs-style bindings | Vi mode with custom `v`/`y` |
| Window/pane numbering | Starts at zero | Starts at one |

Prefix+`k` closes a tmux window immediately, while the stock prefix+`&` alias
still asks for confirmation. Herdr retains `confirm_close = false`.

## Application differences

- Herdr prefix+`O` renames a pane; tmux has no matching binding here.
- Herdr prefix+`g` opens goto. Its other unspecified actions retain Herdr defaults.
- Tmux retains stock session navigation with prefix+`(` / `)`; Herdr's
  configured workspace navigation uses prefix+`P` / `N` and Alt-Up / Alt-Down.
- Herdr's last-pane action can cross tabs/workspaces; tmux's is window-local.
- Tmux prefix+Ctrl-Space sends its primary prefix to the pane. Stock
  prefix+Ctrl-b also invokes `send-prefix`, which sends the primary Ctrl-Space.

## Reloading

After deploying the dotfiles, prefix+`q` reloads either application's config.
Herdr can also reload through `herdr server reload-config`.

If a running tmux server previously loaded another keymap, sourcing this file
will not remove extra bindings left in memory. A fresh server, such as
`tmux -L original-trial new-session`, loads only the deployed config and stock
bindings while existing sessions keep running.
