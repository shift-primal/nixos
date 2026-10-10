local ox = require("config.ox")

return {
	mason = false, -- use the project's node_modules/.bin/oxlint (or PATH)
	-- only run where an oxlint config exists, not in single-file mode
	root_dir = function(bufnr, on_dir)
		local root = ox.lint_root(bufnr)
		if root then
			on_dir(root)
		end
	end,
}
