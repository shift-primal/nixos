local ox = require("config.ox")

return {
	mason = false,
	-- lspconfig prefers node_modules/.bin/biome, a generic-linux binary NixOS cannot run (exit 127)
	cmd = { "biome", "lsp-proxy" },
	-- biome is the default; skip it when the project has opted into ox
	root_dir = function(bufnr, on_dir)
		if ox.active(bufnr) then
			return
		end
		local root = vim.fs.root(bufnr, { "biome.json", "biome.jsonc" })
		if root then
			on_dir(root)
		end
	end,
}
