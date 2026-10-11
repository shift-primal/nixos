require("hyprland.autostart")
require("hyprland.base")
require("hyprland.input")
require("hyprland.animations")
require("hyprland.keybinds")
require("hyprland.rules")
require("hyprland.cursor")

require("noctalia").apply_theme()

local vars = require("hyprland.vars")
-- Per-machine overrides, loaded last so they win: hyprland/hosts/<hostname>.lua,
-- named after the folders in ~/nixos/hosts/.
local host = "hyprland.hosts." .. vars.hostname

if package.searchpath(host, package.path) then
	require(host)
end
