return {
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
}
