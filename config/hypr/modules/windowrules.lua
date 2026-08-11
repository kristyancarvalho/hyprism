hl.layer_rule({
    name = "hyprism-shell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.08,
})
