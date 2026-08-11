local home = assert(os.getenv("HOME"), "HOME is required")
local cache_home = os.getenv("XDG_CACHE_HOME") or home .. "/.cache"
local palette = {
    active_border = "rgb(82b1d3)",
    inactive_border = "rgb(426172)",
}

-- Wallpaper palette generation is optional. A missing or malformed file must
-- never stop Hyprland from loading the built-in dark palette.
local palette_path = cache_home .. "/hyprism/theme/hyprland.lua"
local loader = loadfile(palette_path)
if loader then
    local ok, generated = pcall(loader)
    if ok and type(generated) == "table" then
        palette.active_border = generated.active_border or palette.active_border
        palette.inactive_border = generated.inactive_border or palette.inactive_border
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
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.94,
        shadow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = "rgba(00000066)",
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            new_optimizations = true,
            xray = false,
        },
    },
})
