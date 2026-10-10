return {
	{ "nvim-mini/mini.pairs", enabled = false },

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
		},
	},
}
