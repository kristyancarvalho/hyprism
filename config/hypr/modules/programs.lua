local home = assert(os.getenv("HOME"), "HOME is required")
local config_home = os.getenv("XDG_CONFIG_HOME") or home .. "/.config"
local root = os.getenv("HYPRISM_ROOT") or home .. "/.local/share/hyprism"

local programs = {
    home = home,
    root = root,
    scripts = root .. "/scripts",
    quickshell = config_home .. "/quickshell/hyprism",
    terminal = os.getenv("TERMINAL") or "foot",
    file_manager = "thunar",
    browser = "firefox",
}

package.loaded["hyprism.programs"] = programs
return programs
