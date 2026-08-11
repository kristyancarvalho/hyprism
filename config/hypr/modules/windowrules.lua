-- Quickshell's default layer namespace is "quickshell". Blur translucent shell
-- surfaces; this does not create or modify their exclusive zones.
hl.layer_rule({
    name = "hyprism-shell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.08,
})
