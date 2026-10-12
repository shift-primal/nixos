return {
	"stevearc/conform.nvim",
	opts = function(_, opts)
		local ox = require("config.ox")

		-- vp projects keep oxfmt options in vite.config.ts, which only vp can read
		local function oxc(bufnr)
			if not ox.fmt_root(bufnr) and ox.vp_fmt_root(bufnr) then
				return { "vp_fmt" }
			end
			return { "oxfmt" }
		end

		opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
			markdown = { "prettier" },
			lua = { "stylua" },
			cs = { "csharpier" },
			sql = { "sqlfluff" },
			toml = { "tombi" },
			nix = { "treefmt" },
			javascript = oxc,
			javascriptreact = oxc,
			typescript = oxc,
			typescriptreact = oxc,
			css = oxc,
			html = oxc,
			json = oxc,
			jsonc = oxc,
			json5 = oxc,
			yaml = oxc,
			vue = oxc,
			scss = oxc,
			less = oxc,
		})

		-- conform prefers node_modules/.bin/biome, a generic-linux binary NixOS cannot run
		opts.formatters = vim.tbl_extend("force", opts.formatters or {}, {
			biome = { command = "biome" },
			["biome-check"] = { command = "biome" },
			["biome-organize-imports"] = { command = "biome" },
			-- a project .oxfmtrc wins; otherwise the global ~/.config/oxc/oxfmtrc.json
			oxfmt = {
				args = function(_, ctx)
					if ox.fmt_root(ctx.buf) then
						return { "--stdin-filepath", "$FILENAME" }
					end
					return { "-c", ox.global_fmt, "--stdin-filepath", "$FILENAME" }
				end,
				cwd = function(_, ctx)
					return ox.fmt_root(ctx.buf)
				end,
			},
			vp_fmt = {
				command = "vp",
				args = { "fmt", "--stdin-filepath", "$FILENAME" },
				stdin = true,
				cwd = function(_, ctx)
					return ox.vp_fmt_root(ctx.buf)
				end,
			},
			stylua = {
				prepend_args = { "--indent-type", "Tabs", "--indent-width", "4" },
			},
		})
	end,
}
