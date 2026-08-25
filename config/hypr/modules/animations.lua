hl.config({ animations = { enabled = true } })

hl.curve("hyprism", {
    type = "bezier",
    points = { { 0.2, 0.8 }, { 0.2, 1.0 } },
})

hl.curve("hyprismWindow", {
    type = "spring",
    mass = 1,
    stiffness = 220,
    dampening = 21,
})

hl.animation({ leaf = "windows", enabled = true, speed = 2.4, bezier = "hyprism" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.7, spring = "hyprismWindow", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.4, spring = "hyprismWindow", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.2, bezier = "hyprism" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.4, bezier = "hyprism" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.2, bezier = "hyprism" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.0, bezier = "hyprism" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.8, bezier = "hyprism" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.4, bezier = "hyprism", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.1, bezier = "hyprism", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.2, bezier = "hyprism", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.8, bezier = "hyprism", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.8, bezier = "hyprism", style = "slide" })
