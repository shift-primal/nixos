-- astro-ls loads TypeScript as a JS library, which TS 7 no longer ships
-- (no tsserverlibrary.js). Use the project's TS when it is <= 6, otherwise the
-- TS 6 bundled inside the Nix astro-language-server package.
local function bundled_tsdk()
	local bin = vim.fn.exepath("astro-ls")
	if bin == "" then
		return nil
	end
	local root = vim.fn.resolve(bin):match("^(.-/lib/node_modules/astro%-language%-server)/")
	if not root then
		return nil
	end
	return vim.fn.glob(root .. "/node_modules/.pnpm/typescript@*/node_modules/typescript/lib", false, true)[1]
end

return {
	mason = false,

	-- astro-ls ships Emmet built in; this is the only way to turn it off
	settings = {
		emmet = { showExpandedAbbreviation = "never" },
	},

	before_init = function(_, config)
		local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
		if tsdk == "" or vim.fn.filereadable(tsdk .. "/tsserverlibrary.js") == 0 then
			tsdk = bundled_tsdk()
		end
		config.init_options = config.init_options or {}
		config.init_options.typescript = config.init_options.typescript or {}
		config.init_options.typescript.tsdk = tsdk
	end,

	handlers = {
		-- when tsc type-checks .astro through the content mapper (tsc.lua), drop
		-- astro-ls's copy of the same TypeScript diagnostics
		["textDocument/publishDiagnostics"] = function(err, result, ctx)
			local bufnr = vim.uri_to_bufnr(result.uri)
			if #vim.lsp.get_clients({ bufnr = bufnr, name = "tsc" }) > 0 then
				result.diagnostics = vim.tbl_filter(function(d)
					return d.source ~= "ts"
				end, result.diagnostics)
			end
			vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
		end,
	},
}
