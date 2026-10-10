local ox = require("config.ox")

return {
	mason = false,
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
