local function globs(patterns)
	local args = {}
	for _, p in ipairs(patterns) do
		vim.list_extend(args, { "--glob", p })
	end
	return args
end

return {
	"folke/snacks.nvim",
	opts = {

		picker = {
			grep = {
				hidden = true,
				ignored = true,
			},
			sources = {
				grep = {
					args = globs({
						"!*-lock.{json,yaml,conf}",
						"!node_modules",
						"!drizzle",
						"!*.md",
						"!*.gen.*",
					}),
				},
			},
		},
	},
}
