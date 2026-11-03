return {
	{
		"shift-primal/blink-icon-preview.nvim",
		dependencies = { "folke/snacks.nvim" },
		opts = {},
	},
	{
		"folke/snacks.nvim",
		opts = {
			image = {
				enabled = true,
				doc = {
					enabled = true,
					inline = false,
					max_width = 20,
					max_height = 10,
				},
				convert = {
					magick = {
						vector = { "-density", "192", "-background", "none", "{src}[{page}]", "-resize", "256x256" },
					},
				},
			},
		},
	},
}
