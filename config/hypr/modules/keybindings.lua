local paths = require("hyprism.programs")
local mod = "ALT"
local scripts = paths.scripts
local exec = hl.dsp.exec_cmd

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function script(relative)
    return shell_quote(scripts .. "/" .. relative)
end

local quickshell_ipc = "qs -c " .. shell_quote(paths.quickshell) .. " ipc call "

local function bind(keys, command, options)
    hl.bind(keys, exec(command), options)
end

bind(mod .. " + Return", paths.terminal)
bind(mod .. " + E", paths.file_manager)
bind(mod .. " + B", paths.browser)
bind(mod .. " + R", quickshell_ipc .. "app-launcher toggle")
bind(mod .. " + K", quickshell_ipc .. "wallpaper-picker toggle")
bind(mod .. " + SHIFT + V", quickshell_ipc .. "clipboard toggle")
bind(mod .. " + SHIFT + N", quickshell_ipc .. "shell toggleNetwork")
bind(mod .. " + SHIFT + I", quickshell_ipc .. "shell togglePowerSaver")
bind(mod .. " + SHIFT + E", script("system/reload-shell"))
bind(mod .. " + SHIFT + L", quickshell_ipc .. "power-menu toggle")
bind(mod .. " + M", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
bind(mod .. " + L", "hyprlock")
bind("CTRL + period", quickshell_ipc .. "emoji-picker toggle")

hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
bind(mod .. " + CTRL + left", script("system/move-or-scroll") .. " l")
bind(mod .. " + CTRL + right", script("system/move-or-scroll") .. " r")
hl.bind(mod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

hl.bind(mod .. " + SUPER + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + SUPER + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + SUPER + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mod .. " + SUPER + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -conf"))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind(mod .. " + Tab", quickshell_ipc .. "window-switcher forward")
bind(mod .. " + SHIFT + Tab", quickshell_ipc .. "window-switcher backward")
bind("Alt_L", quickshell_ipc .. "window-switcher commit", { release = true })
bind("Alt_R", quickshell_ipc .. "window-switcher commit", { release = true })

bind(mod .. " + SHIFT + up", script("system/action") .. " volume-up")
bind(mod .. " + SHIFT + down", script("system/action") .. " volume-down")
bind(mod .. " + SHIFT + M", script("system/action") .. " volume-mute")
bind(mod .. " + SUPER + M", script("system/action") .. " mic-mute")
bind("XF86AudioRaiseVolume", script("system/action") .. " volume-up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", script("system/action") .. " volume-down", { locked = true, repeating = true })
bind("XF86AudioMute", script("system/action") .. " volume-mute", { locked = true, repeating = true })
bind("XF86AudioMicMute", script("system/action") .. " mic-mute", { locked = true, repeating = true })
bind("XF86MonBrightnessUp", script("system/action") .. " brightness-up", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", script("system/action") .. " brightness-down", { locked = true, repeating = true })
bind("XF86AudioNext", "playerctl next", { locked = true })
bind("XF86AudioPause", "playerctl play-pause", { locked = true })
bind("XF86AudioPlay", "playerctl play-pause", { locked = true })
bind("XF86AudioPrev", "playerctl previous", { locked = true })

bind(mod .. " + SUPER + K", quickshell_ipc .. "wallpaper random")
bind(mod .. " + SHIFT + S", script("system/action") .. " screenshot-area")
bind(mod .. " + SHIFT + F", script("system/action") .. " screenshot-monitor")
bind(mod .. " + CTRL + P", script("system/action") .. " color-picker")
bind(mod .. " + SHIFT + R", script("system/action") .. " record")
bind(mod .. " + CTRL + S", script("system/action") .. " night-mode toggle")
bind(mod .. " + CTRL + C", "chromium --app=https://chat.openai.com")
bind(mod .. " + CTRL + Y", "chromium --app=https://youtube.com")
bind(mod .. " + CTRL + X", "chromium --app=https://x.com")
bind(mod .. " + CTRL + R", "chromium --app=https://reddit.com")
