return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			astro = require("plugins.lsp.servers.astro"),
			tsc = require("plugins.lsp.servers.tsc"),
			oxlint = require("plugins.lsp.servers.oxlint"),
			biome = {},
			tailwindcss = {},
			lua_ls = {},
			marksman = {},
			lemminx = {},
		},
	},
}
