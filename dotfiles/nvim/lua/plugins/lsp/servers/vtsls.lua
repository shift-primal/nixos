return {
	settings = {
		typescript = {
			format = { enable = false },
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

		javascript = {
			format = { enable = false },
		},
	},

	vtsls = {
		autoUseWorkspaceTsdk = true,
	},

	-- oxlint already reports unused variables/imports; drop tsserver's duplicates.
	handlers = {
		["textDocument/publishDiagnostics"] = function(err, result, ctx)
			local unused = { [6133] = true, [6192] = true, [6196] = true, [6198] = true, [6199] = true, [6205] = true }
			result.diagnostics = vim.tbl_filter(function(d)
				return not unused[tonumber(d.code)]
			end, result.diagnostics)
			vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
		end,
	},

	capabilities = {
		textDocument = {
			colorProvider = { dynamicRegistration = false },
		},
	},
}
