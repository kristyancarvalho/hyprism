local home = assert(os.getenv("HOME"), "HOME is required")
local root = os.getenv("HYPRISM_ROOT") or home .. "/.local/share/hyprism"

local programs = {
    home = home,
    root = root,
    scripts = root .. "/scripts",
    quickshell = os.getenv("QS_CONFIG_NAME") or "default",
    terminal = os.getenv("TERMINAL") or "foot",
    file_manager = "thunar",
    browser = "firefox",
}

package.loaded["hyprism.programs"] = programs
return programs
