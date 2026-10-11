require("hyprland.autostart")
require("hyprland.base")
require("hyprland.monitors")
require("hyprland.input")
require("hyprland.animations")
require("hyprland.keybinds")
require("hyprland.rules")
require("hyprland.cursor")

require("noctalia").apply_theme()

local vars = require("hyprland.vars")
local host = "hyprland.hosts." .. vars.hostname

if package.searchpath(host, package.path) then
	require(host)
end
