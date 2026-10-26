return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			astro = require("plugins.lsp.servers.astro"),
			tsc = require("plugins.lsp.servers.tsc"),
			biome = require("plugins.lsp.servers.biome"),
			oxlint = require("plugins.lsp.servers.oxlint"),
			lua_ls = require("plugins.lsp.servers.lua_ls"),
			marksman = require("plugins.lsp.servers.marksman"),
		},
	},
}
