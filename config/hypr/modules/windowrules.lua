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

hl.window_rule({
    name = "gnome-calculator-dialog",
    match = { initial_class = "^org\\.gnome\\.Calculator$" },
    float = true,
    size = { "monitor_w * 0.28", "monitor_h * 0.52" },
    center = true,
})

hl.window_rule({
    name = "hyprism-keyboard-setup",
    match = { class = "^hyprism-keyboard-setup$" },
    float = true,
    size = { "monitor_w * 0.42", "monitor_h * 0.58" },
    center = true,
})
