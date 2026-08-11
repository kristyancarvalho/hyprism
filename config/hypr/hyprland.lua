local entrypoint = debug.getinfo(1, "S").source
local config_dir = entrypoint:sub(1, 1) == "@" and entrypoint:sub(2):match("(.*/)") or nil

if config_dir then
    package.path = config_dir .. "?.lua;" .. config_dir .. "?/init.lua;" .. package.path
end

require("modules.environment")
require("modules.programs")
require("modules.monitors")
require("modules.general")
require("modules.input")
require("modules.appearance")
require("modules.animations")
require("modules.layouts")
require("modules.windowrules")
require("modules.workspaces")
require("modules.keybindings")
require("modules.autostart")
