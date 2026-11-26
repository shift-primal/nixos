local web = { "oxfmt_project", "prettier_project", "oxfmt", stop_after_first = true }

return {
	"stevearc/conform.nvim",
	opts = function(_, opts)
		local util = require("conform.util")
		local oxfmt_root = util.root_file({ ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" })

		opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
			lua = { "stylua" },
			cs = { "csharpier" },
			toml = { "tombi" },
			nix = { "treefmt_project", "nixfmt", stop_after_first = true },
			markdown = web,
			javascript = web,
			javascriptreact = web,
			typescript = web,
			typescriptreact = web,
			json = web,
			jsonc = web,
			css = web,
			vue = web,
			html = web,
			json5 = web,
			yaml = web,
			scss = web,
			less = web,
		})
		for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
			opts.formatters_by_ft[ft] = nil
		end

		opts.formatters = vim.tbl_extend("force", opts.formatters or {}, {
			oxfmt_project = {
				inherit = "oxfmt",
				require_cwd = true,
				-- ~/.oxfmtrc.json is the global fallback linked by modules/dev/web.nix, not a project config
				cwd = function(self, ctx)
					local root = oxfmt_root(self, ctx)
					if root ~= vim.uv.os_homedir() then
						return root
					end
				end,
			},
			oxfmt = { prepend_args = { "-c", vim.fs.normalize("~/.config/oxc/oxfmtrc.json") } },
			biome = { command = "biome", require_cwd = true },
			["biome-check"] = { command = "biome" },
			treefmt_project = { inherit = "treefmt", require_cwd = true },
			prettier_project = { inherit = "prettier", require_cwd = true },
		})
	end,
}
