local home = assert(os.getenv("HOME"), "HOME is required")
local local_root = home .. "/.local/share/hyprism"
local root = os.getenv("HYPRISM_ROOT")
if not root then
    local marker = io.open(local_root .. "/config/user.json", "r")
    if marker then
        marker:close()
        root = local_root
    else
        root = "/usr/share/hyprism"
    end
end

local programs = {
    home = home,
    root = root,
    scripts = root .. "/scripts",
    cli = "hyprism-shell",
    quickshell = os.getenv("QS_CONFIG_NAME") or "default",
    modifier = "SUPER",
    terminal = os.getenv("TERMINAL") or "kitty",
    file_manager = "thunar",
    browser = "zen-browser",
}

package.loaded["hyprism.programs"] = programs
return programs
