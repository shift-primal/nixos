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

	capabilities = {
		textDocument = {
			colorProvider = { dynamicRegistration = false },
		},
	},
}
