local paths = require("hyprism.programs")

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("HYPRISM_ROOT=" .. paths.root .. " quickshell -p " .. paths.quickshell .. " --no-duplicate --daemonize")
    hl.exec_cmd(paths.scripts .. "/system/action clipboard-watch")
    hl.exec_cmd(paths.scripts .. "/wallpaper restore")

    local polkit = "/usr/lib/polkit-kde-authentication-agent-1"
    local handle = io.open(polkit, "r")
    if handle then
        handle:close()
        hl.exec_cmd(polkit)
    end
end)
