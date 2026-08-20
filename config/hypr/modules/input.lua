hl.config({
    input = {
        kb_layout = "br",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
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
