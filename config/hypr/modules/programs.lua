local home = assert(os.getenv("HOME"), "HOME is required")
local root = os.getenv("HYPRISM_ROOT") or home .. "/.local/share/hyprism"

local programs = {
    home = home,
    root = root,
    scripts = root .. "/scripts",
    cli = home .. "/.local/bin/hyprism-shell",
    quickshell = os.getenv("QS_CONFIG_NAME") or "default",
    modifier = "SUPER",
    terminal = os.getenv("TERMINAL") or "kitty",
    file_manager = "thunar",
    browser = "zen-browser",
}

package.loaded["hyprism.programs"] = programs
return programs
