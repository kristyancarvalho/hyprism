local paths = require("hyprism.programs")
local mod = "ALT"
local scripts = paths.scripts
local exec = hl.dsp.exec_cmd

local function bind(keys, command, options)
    hl.bind(keys, exec(command), options)
end

-- Applications and shell panels.
bind(mod .. " + Return", "hyprism-launch terminal")
bind(mod .. " + E", "hyprism-launch file-manager")
bind(mod .. " + B", "hyprism-launch browser")
bind(mod .. " + R", "qs -p " .. paths.quickshell .. " ipc call app-launcher toggle")
bind(mod .. " + K", "qs -p " .. paths.quickshell .. " ipc call wallpaper-picker toggle")
bind(mod .. " + SHIFT + V", "qs -p " .. paths.quickshell .. " ipc call clipboard toggle")
bind(mod .. " + SHIFT + N", "qs -p " .. paths.quickshell .. " ipc call shell toggleNetwork")
bind(mod .. " + SHIFT + I", "qs -p " .. paths.quickshell .. " ipc call shell togglePowerSaver")
bind(mod .. " + SHIFT + E", scripts .. "/system/reload-shell")
bind(mod .. " + SHIFT + L", "qs -p " .. paths.quickshell .. " ipc call power-menu toggle")
bind(mod .. " + M", "qs -p " .. paths.quickshell .. " ipc call power-menu toggle")
bind(mod .. " + L", "hyprlock")
bind("CTRL + period", "qs -p " .. paths.quickshell .. " ipc call emoji-picker toggle")

-- Window management. Pseudotiling is the 0.56 Lua window dispatcher.
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
bind(mod .. " + CTRL + left", scripts .. "/system/move-or-scroll l")
bind(mod .. " + CTRL + right", scripts .. "/system/move-or-scroll r")
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

-- Alt-Tab advances while held and commits when either Alt key is released.
bind(mod .. " + Tab", "qs -p " .. paths.quickshell .. " ipc call window-switcher forward")
bind(mod .. " + SHIFT + Tab", "qs -p " .. paths.quickshell .. " ipc call window-switcher backward")
bind(mod .. " + Alt_L", "qs -p " .. paths.quickshell .. " ipc call window-switcher commit", { release = true })
bind(mod .. " + Alt_R", "qs -p " .. paths.quickshell .. " ipc call window-switcher commit", { release = true })

-- Audio, brightness, media and OSD feedback.
bind(mod .. " + SHIFT + up", scripts .. "/system/action volume-up")
bind(mod .. " + SHIFT + down", scripts .. "/system/action volume-down")
bind(mod .. " + SHIFT + M", scripts .. "/system/action volume-mute")
bind(mod .. " + SUPER + M", scripts .. "/system/action mic-mute")
bind("XF86AudioRaiseVolume", scripts .. "/system/action volume-up", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", scripts .. "/system/action volume-down", { locked = true, repeating = true })
bind("XF86AudioMute", scripts .. "/system/action volume-mute", { locked = true, repeating = true })
bind("XF86AudioMicMute", scripts .. "/system/action mic-mute", { locked = true, repeating = true })
bind("XF86MonBrightnessUp", scripts .. "/system/action brightness-up", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", scripts .. "/system/action brightness-down", { locked = true, repeating = true })
bind("XF86AudioNext", "playerctl next", { locked = true })
bind("XF86AudioPause", "playerctl play-pause", { locked = true })
bind("XF86AudioPlay", "playerctl play-pause", { locked = true })
bind("XF86AudioPrev", "playerctl previous", { locked = true })

-- Utilities.
bind(mod .. " + SUPER + K", "qs -p " .. paths.quickshell .. " ipc call wallpaper random")
bind(mod .. " + SHIFT + S", scripts .. "/system/action screenshot-area")
bind(mod .. " + SHIFT + F", scripts .. "/system/action screenshot-monitor")
bind(mod .. " + CTRL + P", scripts .. "/system/action color-picker")
bind(mod .. " + SHIFT + R", scripts .. "/system/action record")
bind(mod .. " + CTRL + S", scripts .. "/system/action night-mode toggle")
bind(mod .. " + CTRL + C", "chromium --app=https://chat.openai.com")
bind(mod .. " + CTRL + Y", "chromium --app=https://youtube.com")
bind(mod .. " + CTRL + X", "chromium --app=https://x.com")
bind(mod .. " + CTRL + R", "chromium --app=https://reddit.com")
