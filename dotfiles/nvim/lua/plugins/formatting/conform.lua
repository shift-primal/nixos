return {
	"stevearc/conform.nvim",
	opts = function(_, opts)
		local ox = require("config.ox")

		-- oxfmt if the project root has an ox config, otherwise the fallback
		-- chain. Never biome or prettier inside an ox project.
		local function pick(fallback_chain)
			return function(bufnr)
				if ox.fmt_root(bufnr) then
					return { "oxfmt" }
				end
				return fallback_chain
			end
		end

		-- ox projects own their ignore list (oxfmt skips markdown there), so
		-- format nothing instead of falling back to prettier
		local function pick_or_none(fallback_chain)
			return function(bufnr)
				if ox.active(bufnr) then
					return {}
				end
				return fallback_chain
			end
		end

		local biome_js = { "biome", "biome-organize-imports" }

		opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
			markdown = pick_or_none({ "prettier" }),
			lua = { "stylua" },
			cs = { "csharpier" },
			sql = { "sqlfluff" },
			toml = { "tombi" },
			-- treefmt.toml owns the nixfmt options and the hardware-config exclude
			nix = { "treefmt" },
			javascript = pick(biome_js),
			javascriptreact = pick(biome_js),
			typescript = pick(biome_js),
			typescriptreact = pick(biome_js),
			css = pick({ "biome" }),
			html = pick({ "biome" }),
			json = pick({ "biome" }),
			jsonc = pick({ "biome" }),
			json5 = pick({}),
			yaml = pick({}),
			vue = pick({}),
			scss = pick({}),
			less = pick({}),
		})

		-- conform prefers node_modules/.bin/biome, a generic-linux binary NixOS cannot run
		opts.formatters = vim.tbl_extend("force", opts.formatters or {}, {
			biome = { command = "biome" },
			["biome-check"] = { command = "biome" },
			["biome-organize-imports"] = { command = "biome" },
			stylua = {
				prepend_args = { "--indent-type", "Tabs", "--indent-width", "4" },
			},
		})
	end,
}
