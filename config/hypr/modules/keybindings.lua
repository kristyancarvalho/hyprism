local paths = require("hyprism.programs")
local mod = paths.modifier
local scripts = paths.scripts
local exec = hl.dsp.exec_cmd

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local cli = shell_quote(paths.cli)

local function script(relative)
    return shell_quote(scripts .. "/" .. relative)
end

local quickshell_ipc = script("system/shell-ipc") .. " shell "

local function bind(keys, command, options)
    hl.bind(keys, exec(command), options)
end

bind(mod .. " + Return", paths.terminal)
bind(mod .. " + E", paths.file_manager)
bind(mod .. " + B", paths.browser)
bind(mod .. " + R", cli .. " open launcher")
bind(mod .. " + K", cli .. " open wallpapers")
bind(mod .. " + SHIFT + V", cli .. " open clipboard")
bind(mod .. " + SHIFT + N", cli .. " open network")
bind(mod .. " + SHIFT + I", quickshell_ipc .. "togglePowerSaver")
bind(mod .. " + SHIFT + E", cli .. " reload")
bind(mod .. " + SHIFT + L", cli .. " open power")
bind(mod .. " + M", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
bind(mod .. " + L", cli .. " lock")
bind("CTRL + period", cli .. " open emoji")

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

hl.bind(mod .. " + ALT + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -conf"))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind(mod .. " + Tab", quickshell_ipc .. "switcherForward")
bind(mod .. " + SHIFT + Tab", quickshell_ipc .. "switcherBackward")
bind("Super_L", quickshell_ipc .. "switcherCommit", { release = true })
bind("Super_R", quickshell_ipc .. "switcherCommit", { release = true })

bind(mod .. " + SHIFT + up", script("system/action") .. " volume-up")
bind(mod .. " + SHIFT + down", script("system/action") .. " volume-down")
bind(mod .. " + SHIFT + M", script("system/action") .. " volume-mute")
bind(mod .. " + ALT + M", script("system/action") .. " mic-mute")
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

bind(mod .. " + ALT + K", cli .. " wallpaper random")
bind(mod .. " + SHIFT + S", cli .. " screenshot region")
bind(mod .. " + SHIFT + F", cli .. " screenshot monitor")
bind(mod .. " + CTRL + P", cli .. " color")
bind(mod .. " + SHIFT + R", cli .. " recording")
bind(mod .. " + CTRL + S", cli .. " night-mode toggle")
bind(mod .. " + CTRL + C", "chromium --app=https://chat.openai.com")
bind(mod .. " + CTRL + Y", "chromium --app=https://youtube.com")
bind(mod .. " + CTRL + X", "chromium --app=https://x.com")
bind(mod .. " + CTRL + R", "chromium --app=https://reddit.com")
