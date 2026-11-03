local blue = "rgb(7aa2f7)"
local purple = "rgb(bb9af7)"
local red = "rgb(f7768e)"
local bg = "rgb(1a1b26)"
local fg = "rgb(c0caf5)"
local muted = "rgb(414868)"

hl.config({
	general = {
		col = {
			active_border = blue,
			inactive_border = muted,
		},
	},
	group = {
		col = {
			border_active = purple,
			border_inactive = muted,
			border_locked_active = red,
			border_locked_inactive = muted,
		},
		groupbar = {
			col = {
				active = purple,
				inactive = muted,
				locked_active = red,
				locked_inactive = muted,
			},
			text_color = bg,
			text_color_inactive = fg,
			text_color_locked_active = bg,
			text_color_locked_inactive = fg,
		},
	},
})
