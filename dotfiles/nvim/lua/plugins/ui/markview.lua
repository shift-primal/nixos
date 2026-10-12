return {
	"OXY2DEV/markview.nvim",
	lazy = false,

	opts = {
		preview = {
			icon_provider = "devicons", -- "mini" or "devicons"
		},
	},

	-- Completion for `blink.cmp`
	dependencies = { "saghen/blink.cmp" },
}
