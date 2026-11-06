-- Plugins are built by Nix (~/nixos/pkgs) against the running Hyprland; hyprpm does not work on NixOS.
local plugins = require("hyprland.vars").plugins

hl.plugin.load(plugins.autoscroll)

hl.config({
	plugin = {
		hypr_autoscroll = {
			direct_activation = false,
		},
	},
})
