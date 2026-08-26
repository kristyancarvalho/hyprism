local paths = require("hyprism.programs")

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(shell_quote(paths.scripts .. "/system/action") .. " clipboard-watch")
    hl.exec_cmd(shell_quote(paths.scripts .. "/system/start-shell"))
    hl.exec_cmd(shell_quote(paths.scripts .. "/wallpaper") .. " restore")
end)
