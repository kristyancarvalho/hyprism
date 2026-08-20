hl.layer_rule({
    name = "hyprism-shell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.08,
})

hl.window_rule({
    name = "kitty-background-blur",
    match = { class = "^kitty$" },
    no_blur = false,
})
