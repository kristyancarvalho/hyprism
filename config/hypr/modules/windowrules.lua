hl.layer_rule({
    name = "hyprism-shell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.08,
})

hl.window_rule({
    name = "foot-background-blur",
    match = { class = "^foot$" },
    no_blur = false,
})
