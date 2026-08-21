hl.config({
    input = {
        kb_layout = "br",
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

hl.device({
    name = "at-translated-set-2-keyboard",
    kb_layout = "br",
})

local external_keyboards = {
    "2.4g-wireless-device",
    "2.4g-wireless-device-consumer-control",
    "2.4g-wireless-device-1",
    "2.4g-wireless-device-system-control",
    "sonix-ak820",
    "sonix-ak820-consumer-control",
    "sonix-ak820-keyboard",
    "sonix-ak820-system-control",
}

for _, keyboard in ipairs(external_keyboards) do
    hl.device({
        name = keyboard,
        kb_layout = "us",
        kb_variant = "intl",
    })
end
