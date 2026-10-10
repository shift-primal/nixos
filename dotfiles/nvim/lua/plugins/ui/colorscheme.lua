return {
	{
		"shatur/neovim-ayu",
		main = "ayu",
		opts = {
			overrides = function()
				local colors = require("ayu.colors")
				colors.accent = "#D75858"
				return {
					Normal = { bg = "None" },
					NormalFloat = { bg = "none" },
					ColorColumn = { bg = "None" },
					SignColumn = { bg = "None" },
					Folded = { bg = "None" },
					FoldColumn = { bg = "None" },
					CursorLine = { bg = "None" },
					CursorColumn = { bg = "None" },
					LspReferenceText = { bold = false },
					LspReferenceRead = { bold = false },
					LspReferenceWrite = { bold = false },

					WinSeparator = { fg = colors.ui, bg = "None" },
					FloatBorder = { fg = colors.ui, bg = "None" },
				}
			end,
		},
	},

	{
		"LazyVim/LazyVim",
		opts = { colorscheme = "ayu-dark-bordered" },
	},
}
