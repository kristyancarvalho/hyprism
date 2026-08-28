hl.config({
    input = {
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
    gestures = {
        workspace_swipe_distance = 320,
        workspace_swipe_min_speed_to_force = 28,
        workspace_swipe_cancel_ratio = 0.38,
        workspace_swipe_create_new = false,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 12,
        workspace_swipe_forever = false,
        workspace_swipe_invert = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

local cache_home = os.getenv("XDG_CACHE_HOME") or ((os.getenv("HOME") or "") .. "/.cache")
local keyboard_config = loadfile(cache_home .. "/hyprism/state/keyboard.lua")
if keyboard_config then
    keyboard_config()
end
