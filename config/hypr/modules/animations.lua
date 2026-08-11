hl.config({ animations = { enabled = true } })

hl.curve("hyprism", {
    type = "bezier",
    points = { { 0.2, 0.0 }, { 0.0, 1.0 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "hyprism", style = "popin 85%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "hyprism", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "hyprism" })
