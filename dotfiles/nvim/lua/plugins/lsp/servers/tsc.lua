-- lspconfig's tsc config; root_dir and cmd share its cache of which tsc binary
-- the project uses, so both must come from the same load
local upstream
local function lspconfig_tsc()
	upstream = upstream or loadfile(vim.api.nvim_get_runtime_file("lsp/tsc.lua", false)[1])()
	return upstream
end

-- .astro needs TS 7.1+ and @astrojs/ts-content-mapper registered in tsconfig.json;
-- elsewhere astro-ls (astro.lua) covers it alone
local function has_content_mappers(bufnr)
	local tsconfig =
		vim.fs.find("tsconfig.json", { upward = true, path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)) })[1]
	if not tsconfig then
		return false
	end
	local ok, lines = pcall(vim.fn.readfile, tsconfig)
	return ok and table.concat(lines, "\n"):find('"contentMappers"', 1, true) ~= nil
end

return {
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"astro",
	},

	cmd = function(dispatchers, config)
		return lspconfig_tsc().cmd(dispatchers, config)
	end,

	root_dir = function(bufnr, on_dir)
		if vim.bo[bufnr].filetype == "astro" and not has_content_mappers(bufnr) then
			return
		end
		lspconfig_tsc().root_dir(bufnr, on_dir)
	end,

	-- content mappers run code from node_modules; TS only loads them with this opt-in
	init_options = {
		runExternalCode = true,
	},

	settings = {
		["js/ts"] = {
			format = { enabled = false },
			preferences = {
				importModuleSpecifier = "non-relative",
				autoImportFileExcludePatterns = {
					"**/node_modules/@base-ui/react/**",
				},
			},

			suggest = {
				autoImports = true,
				includeCompletionsForModuleExports = true,
			},

			inlayHints = {
				parameterNames = { enabled = "all" },
				parameterTypes = { enabled = false },
				variableTypes = { enabled = false },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = false },
				enumMemberValues = { enabled = true },
			},
		},
	},

	handlers = {
		["textDocument/publishDiagnostics"] = function(err, result, ctx)
			local bufnr = vim.uri_to_bufnr(result.uri)
			local linted = #vim.lsp.get_clients({ bufnr = bufnr, name = "oxlint" }) > 0
				or #vim.lsp.get_clients({ bufnr = bufnr, name = "biome" }) > 0
			if linted then
				local unused =
					{ [6133] = true, [6192] = true, [6196] = true, [6198] = true, [6199] = true, [6205] = true }
				result.diagnostics = vim.tbl_filter(function(d)
					return not unused[tonumber(d.code)]
				end, result.diagnostics)
			end
			vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
		end,
	},

	capabilities = {
		textDocument = {
			colorProvider = { dynamicRegistration = false },
		},
	},
}
