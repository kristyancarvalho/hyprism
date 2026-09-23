local home = assert(os.getenv("HOME"), "HOME is required")
local cache_home = os.getenv("XDG_CACHE_HOME") or home .. "/.cache"
local appearance_cache = os.getenv("HYPRISM_CACHE_DIR") or cache_home .. "/hyprism"
local palette = {
    active_border = "rgb(355b6e)",
    inactive_border = "rgb(293943)",
    shadow = "rgba(0000006e)",
}

local palette_path = appearance_cache .. "/theme/hyprland.lua"
local loader = loadfile(palette_path)
if loader then
    local ok, generated = pcall(loader)
    if ok and type(generated) == "table" then
        palette.active_border = generated.active_border or palette.active_border
        palette.inactive_border = generated.inactive_border or palette.inactive_border
        palette.shadow = generated.shadow or palette.shadow
    end
end

local appearance = {
    rounding = 14,
    inactive_opacity = 0.94,
    blur = { enabled = true, size = 5, passes = 2 },
}
local appearance_loader = loadfile(appearance_cache .. "/theme/appearance.lua")
if appearance_loader then
    local ok, generated = pcall(appearance_loader)
    if ok and type(generated) == "table" and type(generated.rounding) == "number" and type(generated.inactive_opacity) == "number" and type(generated.blur) == "table" and type(generated.blur.enabled) == "boolean" and type(generated.blur.size) == "number" and type(generated.blur.passes) == "number" then
        appearance = generated
    end
end

hl.config({
    general = {
        col = {
            active_border = palette.active_border,
            inactive_border = palette.inactive_border,
        },
    },
    decoration = {
        rounding = appearance.rounding,
        rounding_power = 3,
        active_opacity = 1.0,
        inactive_opacity = appearance.inactive_opacity,
        shadow = {
            enabled = true,
            range = 20,
            render_power = 2,
            color = palette.shadow,
        },
        blur = {
            enabled = appearance.blur.enabled,
            size = appearance.blur.size,
            passes = appearance.blur.passes,
            new_optimizations = true,
            xray = false,
        },
    },
})
