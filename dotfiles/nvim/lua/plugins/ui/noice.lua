return {
	"folke/noice.nvim",
	opts = {
		lsp = { hover = { silent = true } },
		routes = {
			{
				filter = { event = "lsp", kind = "progress" },
				opts = { skip = true },
			},
		},
	},
}
