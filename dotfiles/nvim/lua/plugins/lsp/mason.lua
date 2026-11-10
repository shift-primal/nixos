return {
	{
		"mason-org/mason.nvim",
		-- LazyVim's extras list formatters and linters that mise and Nix already provide
		opts = function(_, opts)
			opts.ensure_installed = {}
		end,
	},
	{ "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
