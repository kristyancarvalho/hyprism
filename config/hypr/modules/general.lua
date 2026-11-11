local home = assert(os.getenv("HOME"), "HOME is required")
local cache_home = os.getenv("XDG_CACHE_HOME") or home .. "/.cache"
local layout_cache = os.getenv("HYPRISM_CACHE_DIR") or cache_home .. "/hyprism"
local layouts = { scrolling = true, dwindle = true }
local layout = "dwindle"

local layout_loader = loadfile(layout_cache .. "/theme/layout.lua")
if layout_loader then
    local ok, generated = pcall(layout_loader)
    if ok and type(generated) == "table" and layouts[generated.layout] then
        layout = generated.layout
    end
end

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 0,
        layout = layout,
        resize_on_border = true,
        allow_tearing = false,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        force_default_wallpaper = 0,
    },
})
