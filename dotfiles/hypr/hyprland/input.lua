local keyboard = require("hyprland.vars").keyboard

hl.config({
	input = {
		kb_layout = keyboard.layout,
		kb_variant = keyboard.variant,
		accel_profile = "flat",
		sensitivity = -0.2,

		repeat_rate = 30,
		repeat_delay = 250,
		numlock_by_default = true,

		touchpad = {
			natural_scroll = true,
			clickfinger_behavior = true,
		},
	},
})
