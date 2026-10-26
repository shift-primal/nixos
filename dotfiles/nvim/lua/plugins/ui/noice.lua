return {
	"folke/noice.nvim",
	opts = {
		-- noice handles each server's hover reply separately, so one with nothing to
		-- say (e.g. tailwindcss off a class) notifies even when another has a popup
		lsp = { hover = { silent = true } },
		routes = {
			{
				filter = { event = "lsp", kind = "progress" },
				opts = { skip = true },
			},
		},
	},
}
