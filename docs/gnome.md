# GNOME desktop setup

Ubuntu workstation bootstrap also applies power and display preferences using `scripts/bootstrap/configure_gnome_power.sh`. To reapply only these settings from your logged-in GNOME session, run:

```bash
mise run setup:gnome:power
```

To select the Ubuntu profile explicitly, use `mise -C bootstrap -E workstation-ubuntu run setup:gnome:power`. You can also run `sh scripts/bootstrap/configure_gnome_power.sh` directly, without sudo.

This enables battery percentage, selects the `power-saver` profile, enables automatic suspend after 30 minutes of inactivity while plugged in, enables idle screen dimming and automatic power saver on low battery (where supported), and enables Night Light with its automatic sunset-to-sunrise schedule. Battery suspend timing, brightness levels, and Night Light temperature remain unchanged. GNOME determines sunset and sunrise using the current location; the script does not copy machine-specific coordinates. The task requires `gsettings`, `powerprofilesctl`, and a running power-profiles-daemon service. It skips non-Ubuntu profiles and sessions without GNOME or a desktop session bus.

Workstation bootstrap configures application defaults automatically after dotfile deployment. The Ubuntu workstation profile selects Ghostty (`ghostty_ghostty.desktop`) and Zen (`zen.desktop`). This step requires a logged-in desktop session; if bootstrap ran over SSH, run `mise run setup:defaults` after desktop login. Server bootstrap does not configure application defaults.

After editing your defaults, run `mise run setup:defaults` to apply only application defaults. To select a profile explicitly, use `mise -C bootstrap -E workstation-ubuntu run setup:defaults`. Neither command reruns bootstrap.

Set `default_terminal` and `default_browser` in a workstation profile's `[vars]` table to change its application desktop IDs. Profiles without these values skip this step. Machine-specific choices can override the variables in an untracked `bootstrap/mise.local.toml`. The script checks that the applications and XDG tools are installed before applying settings. It sets HTTP, HTTPS, HTML and XHTML associations, and puts the terminal first in `~/.config/xdg-terminals.list`, preserving existing fallbacks. GNOME is configured to use `xdg-terminal-exec`; other desktops must also use that launcher for terminal selection. Desktop-specific terminal preference files can take precedence over the generic list.

Dotfile deployment copies `~/Pictures/wallpapers/catppuccin-mocha.png` into your home directory. To replace an existing symlink with a copy, run `mise run dotfiles:apply` and accept the force retry if prompted.

Ubuntu workstation bootstrap runs `setup:gnome:desktop` after deploying dotfiles. It selects this wallpaper in GNOME for both light and dark mode where supported, using the `zoom` scaling option. To apply it again from your GNOME session:

```bash
mise run setup:gnome:desktop
```

The task skips other profiles and sessions without GNOME or a desktop session bus. If bootstrap ran over SSH or before desktop login, run it after logging in. The script lives at `scripts/bootstrap/configure_gnome_desktop.sh`. It also selects the dark appearance with a purple accent where the GNOME version supports accent colors and restores the saved Ubuntu Dock preferences: bottom position, automatic hiding (`dock-fixed=false`), and a dock that does not extend across the whole screen. Network mounts are shown, limited to mounted volumes. Dock preferences are skipped when the extension schema is unavailable.

Pinned apps are restored in this order: Files, Zen, Helium, VS Code, Ghostty, Obsidian, and Discord. The corresponding desktop IDs are stored in the script; install the matching applications on the destination machine for their pins to appear. Running `setup:gnome:desktop` replaces the current pin order.

The task also saves GNOME shortcuts and selects nine fixed workspaces:

| Shortcut | Action |
| --- | --- |
| Super + H / L | Previous / next window in recent-use order |
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

Alt + Tab and Super + Tab switch applications in recent-use order across all workspaces; add Shift to cycle backward. Hold Alt and press Tab repeatedly to move through the list, then release Alt to activate the selected app. Super + H replaces the default minimize shortcut; Alt + F9 still minimizes windows. Super + I/K are unassigned: built-in GNOME has no directional window focus. Half-screen snapping uses Ubuntu’s enabled Tiling Assistant extension and works on maximized windows too. If its schema is unavailable, setup skips the two snapping bindings and prints a message; install and enable Tiling Assistant, then re-run setup. Other shortcuts use built-in GNOME actions. Numbered application shortcuts in GNOME Shell and the existing Ubuntu Dock are disabled to free workspace bindings; the dock's Super + Q overlay shortcut is also disabled. Re-running the task restores these saved bindings. Browser and file-manager launchers use the configured defaults; terminal selection uses the launcher configured during workstation bootstrap.

Ptyxis is Ubuntu's built-in terminal starting with Ubuntu 25.10. Terminal setup creates `catppuccin-mocha` and `catppuccin-latte` profiles and selects Caskaydia Cove Nerd Font Mono at 12 points for Ptyxis. Workstation bootstrap applies them after font installation, with Mocha as the default. Existing profiles are preserved. The task skips sessions without a desktop bus or the Ptyxis schema; it does not install Ptyxis.

```bash
mise run setup:gnome:terminal
# Select either default directly from the checkout:
python3 scripts/bootstrap/configure_ptyxis.py latte
python3 scripts/bootstrap/configure_ptyxis.py mocha
```

Choose either profile in Ptyxis preferences or its new-tab menu. The default applies to new terminals; restored tabs may retain their existing profile. Re-running bootstrap restores Mocha as the default. The profiles select the built-in `Catppuccin Mocha` and `Catppuccin Latte` palettes; no custom palette files or downloads are needed. Font installation already includes the `CascadiaCode` Nerd Fonts archive; run `mise run setup:fonts` if needed. This task configures Ptyxis appearance; application launcher defaults are managed separately by `setup:defaults`.
