local function project_root()
	return vim.fs.root(0, { ".git", "package.json" }) or vim.fn.getcwd()
end

return {
	{
		"mfussenegger/nvim-dap",
		optional = true,
		opts = function()
			local dap = require("dap")

			for _, language in ipairs({ "typescript", "javascript" }) do
				dap.configurations[language] = dap.configurations[language] or {}
				table.insert(dap.configurations[language], 1, {
					type = "pwa-node",
					request = "launch",
					name = "Debug Vitest (current file)",
					program = function()
						return project_root() .. "/node_modules/vitest/vitest.mjs"
					end,
					args = { "run", "${file}", "--no-file-parallelism" },
					cwd = function()
						return project_root()
					end,
					sourceMaps = true,
					resolveSourceMapLocations = function()
						return { project_root() .. "/**", "!**/node_modules/**" }
					end,
					console = "integratedTerminal",
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				})
			end
		end,
	},
}
