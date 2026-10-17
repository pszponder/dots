# GNOME desktop setup

Dotfile deployment copies `~/Pictures/wallpapers/catppuccin-mocha.png` into your home directory. To replace an existing symlink with a copy, run `mise run dotfiles:apply` and accept the force retry if prompted.

Ubuntu workstation bootstrap runs `setup:desktop` after deploying dotfiles. It selects this wallpaper in GNOME for both light and dark mode where supported, using the `zoom` scaling option. To apply it again from your GNOME session:

```bash
mise run setup:desktop
```

The task skips other profiles and sessions without GNOME or a desktop session bus. If bootstrap ran over SSH or before desktop login, run it after logging in. The script lives at `scripts/bootstrap/configure_desktop.sh`. It also selects the dark appearance with a purple accent where the GNOME version supports accent colors and restores the saved Ubuntu Dock preferences: bottom position, automatic hiding (`dock-fixed=false`), and a dock that does not extend across the whole screen. Network mounts are shown, limited to mounted volumes. Dock preferences are skipped when the extension schema is unavailable.

Pinned apps are restored in this order: Files, Zen, Helium, VS Code, Ghostty, Obsidian, and Discord. The corresponding desktop IDs are stored in the script; install the matching applications on the destination machine for their pins to appear. Running `setup:desktop` replaces the current pin order.

The task also saves GNOME shortcuts and selects nine fixed workspaces:

| Shortcut | Action |
| --- | --- |
| Super + H / L | Previous / next window in recent-use order (Alt + Tab also cycles windows) |
| Super + Shift + H / L | Snap the active window to the left / right half |
| Super + Shift + J | Minimize the active window |
| Super + Shift + K | Maximize the active window |
| Super + 1–9 | Switch to workspace 1–9 |
| Super + Shift + 1–9 | Move the active window to workspace 1–9 |
| Super + Q | Close the active window (other application windows may stay open) |
| Super + Enter | Launch the terminal through GNOME's terminal launcher |
| Super + Shift + Enter | Launch the default browser |
| Super + F | Open the home folder in the default file manager |
| Super + M | Toggle maximize / restore |
| Super + Ctrl + L | Lock the screen |
| Super + V | Open notifications |

Super + Tab still switches applications. Super + H replaces the default minimize shortcut; Alt + F9 still minimizes windows. Super + I/K are unassigned: built-in GNOME has no directional window focus. Half-screen snapping uses Ubuntu’s enabled Tiling Assistant extension and works on maximized windows too. If its schema is unavailable, setup skips the two snapping bindings and prints a message; install and enable Tiling Assistant, then re-run setup. Other shortcuts use built-in GNOME actions. Numbered application shortcuts in GNOME Shell and the existing Ubuntu Dock are disabled to free workspace bindings; the dock's Super + Q overlay shortcut is also disabled. Re-running the task restores these saved bindings. Browser and file-manager launchers use the configured defaults; terminal selection depends on the distribution's GNOME terminal launcher configuration.
