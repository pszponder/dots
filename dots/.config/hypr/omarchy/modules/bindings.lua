-- Personal Hyprland keybindings. Omarchy defaults are disabled in hyprland.lua.
-- Print the active bindings with: omarchy menu keybindings --print

-- Menus and window controls
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("CTRL + ALT + DELETE", "Close all windows", "omarchy-hyprland-window-close-all")

-- Keybinding help
o.bind("SUPER + SHIFT + SLASH", "Keybindings", "omarchy-menu-keybindings")
-- o.bind("SUPER + CTRL + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + CTRL + SHIFT + T", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + CTRL + SHIFT + H", "Herdr keybindings", "omarchy-menu-herdr-keybindings")

-- Focus and move windows with vim keys
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Layout and workspace controls
local function layout_bind(bindings)
  return function()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if workspace and bindings[workspace.tiled_layout] then
      hl.dispatch(bindings[workspace.tiled_layout])
    end
  end
end

o.bind("SUPER + ALT + R", "Toggle dwindle/scrolling layout", "omarchy-hyprland-workspace-layout-toggle")
local function column_layout_bind(scrolling_direction)
  return layout_bind({
    dwindle = hl.dsp.layout("togglesplit"),
    scrolling = hl.dsp.layout("consume_or_expel " .. scrolling_direction),
  })
end

o.bind("SUPER + bracketleft", "Toggle split / consume previous column", column_layout_bind("prev"))
o.bind("SUPER + bracketright", "Toggle split / consume next column", column_layout_bind("next"))
o.bind("SUPER + ALT + J", "Toggle split / consume previous column", column_layout_bind("prev"))
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + M", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + ALT + M", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + TAB", "Focus next window", hl.dsp.window.cycle_next())
o.bind("SUPER + SHIFT + TAB", "Focus previous window", hl.dsp.window.cycle_next({ next = false }))

-- Scratchpad
o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Workspace switching and moving windows to workspaces
  -- Move to workspaces 1-10 with Super + 1-0
  -- Move windows to workspaces 1-10 with Super + Shift + 1-0
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- Applications
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + ALT + RETURN", "Tmux terminal", { omarchy = "terminal-tmux" })
o.bind("SUPER + CTRL + RETURN", "Herdr terminal", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + RETURN", "Browser", { omarchy = "browser" })
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + SHIFT + F", "File manager (terminal cwd)", { omarchy = "nautilus-cwd" })
o.bind("SUPER + E", "Editor", { omarchy = "editor" })
o.bind("SUPER + SHIFT + Z", "Zed", { launch = "zed", focus = "zed" })
o.bind("SUPER + O", "Obsidian", { launch = "obsidian", focus = "obsidian" })
o.bind("SUPER + SHIFT + D", "Docker (LazyDocker)", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + ALT + M", "Music (cliamp)", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + B", "Activity (btop)", { tui = "btop" })
o.bind("SUPER + SHIFT + Q", "Calculator", "omacalc")
o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })
o.bind("SUPER + CTRL + E", "Emojis", "omarchy-shell shell toggle omarchy.emojis")

-- Web apps
o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + G", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + M", "YouTube Music", { webapp = "https://music.youtube.com/" })
o.bind("SUPER + SHIFT + E", "Gmail", { webapp = "https://mail.google.com/" })
o.bind("SUPER + SHIFT + ALT + E", "New email", { webapp = "https://mail.google.com/mail/u/0/#compose" })

-- Clipboard. Use terminal-native shortcuts in terminal windows and conventional
-- shortcuts elsewhere. Split key presses avoid leaving a synthetic key held.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

o.bind("SUPER + C", "Universal copy", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"))
o.bind("SUPER + X", "Universal cut", function()
  if not active_window_is_terminal() then
    send_shortcut_once("CTRL", "X")()
  end
end)
o.bind("SUPER + V", "Universal paste", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"))
o.bind("SUPER + CTRL + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Capture and screen recording
o.bind("SUPER + CTRL + C", "Capture menu", "omarchy-menu toggle capture")
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")
o.bind("ALT + PRINT", "Screen recording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text from screenshot", "omarchy-capture-text")
o.bind("SUPER + ALT + code:34", "Make webcam overlay smaller", "omarchy-capture-webcam-resize smaller")
o.bind("SUPER + ALT + code:35", "Make webcam overlay larger", "omarchy-capture-webcam-resize larger")

-- Chromium's Omarchy extensions handle these browser shortcuts:
-- Alt + Shift + L copies the current URL; Alt + Shift + D downloads page video.

-- Dictation shortcuts are available when Voxtype is installed.
if o.cmd_present("voxtype") then
  hl.unbind("SUPER + R")
  o.bind("SUPER + R", "Start dictation (push-to-talk)", "voxtype record start")
  o.bind("SUPER + R", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
  o.bind("SUPER + CTRL + X", "Toggle dictation", "voxtype record toggle")
  o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start")
  o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
end

-- Media-layer volume controls (Omarchy defaults are disabled in hyprland.lua).
o.bind("XF86AudioRaiseVolume", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
o.bind("XF86AudioPlay", "Play", "omarchy-shell media playPause", { locked = true })
o.bind("XF86AudioPause", "Pause", "omarchy-shell media playPause", { locked = true })
o.bind("XF86AudioNext", "Next track", "omarchy-shell media next", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", "omarchy-brightness-keyboard up", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", "omarchy-brightness-keyboard down", { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "omarchy-brightness-keyboard cycle", { locked = true })