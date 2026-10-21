local web = { "oxfmt_project", "prettier_project", "oxfmt", stop_after_first = true }
local web_biome = { "oxfmt_project", "biome", "prettier_project", "oxfmt", stop_after_first = true }

return {
	"stevearc/conform.nvim",
	opts = function(_, opts)
		local util = require("conform.util")
		local oxfmt_root = util.root_file({ ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" })

		opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
			markdown = { "prettier" },
			lua = { "stylua" },
			cs = { "csharpier" },
			toml = { "tombi" },
			nix = { "treefmt" },
			javascript = web_biome,
			javascriptreact = web_biome,
			typescript = web_biome,
			typescriptreact = web_biome,
			json = web_biome,
			jsonc = web_biome,
			css = web_biome,
			vue = web_biome,
			astro = web_biome,
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
				-- ~/.oxfmtrc.json is the global fallback (home/dotfiles.nix), not a project config
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
			prettier_project = { inherit = "prettier", require_cwd = true },
			stylua = {
				prepend_args = { "--indent-type", "Tabs", "--indent-width", "4" },
			},
		})
	end,
}
