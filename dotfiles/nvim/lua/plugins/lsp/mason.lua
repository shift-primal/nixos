return {
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = {}
		end,
	},
	{ "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
