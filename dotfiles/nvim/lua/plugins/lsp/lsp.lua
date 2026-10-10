return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			vtsls = require("plugins.lsp.servers.vtsls"),
			biome = require("plugins.lsp.servers.biome"),
			oxlint = require("plugins.lsp.servers.oxlint"),
		},
	},
}
