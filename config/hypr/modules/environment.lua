local home = assert(os.getenv("HOME"), "HOME is required")
local data_dirs = {}
local known_data_dirs = {}

local function add_data_dir(path)
    if path ~= "" and not known_data_dirs[path] then
        table.insert(data_dirs, path)
        known_data_dirs[path] = true
    end
end

add_data_dir(home .. "/.local/share/flatpak/exports/share")
add_data_dir("/var/lib/flatpak/exports/share")
for path in string.gmatch(os.getenv("XDG_DATA_DIRS") or "", "([^:]+)") do
    add_data_dir(path)
end
add_data_dir("/usr/local/share")
add_data_dir("/usr/share")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("XDG_DATA_DIRS", table.concat(data_dirs, ":"))
hl.env("TERMINAL", "kitty")
hl.env("QS_CONFIG_NAME", "default")
