return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			astro = require("plugins.lsp.servers.astro"),
			tsc = require("plugins.lsp.servers.tsc"),
			oxlint = require("plugins.lsp.servers.oxlint"),
			biome = { mason = false },
			ruff = { mason = false },
			lua_ls = { mason = false },
			nil_ls = { mason = false },
			omnisharp = { mason = false },
			fsautocomplete = { mason = false },
			tailwindcss = {},
			marksman = {},
			lemminx = {},
		},
	},
}
