-- document_color crashes with an assertion when conform applies text edits
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.lsp.document_color.enable(false, { bufnr = args.buf })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "nix",
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.spell = false
		vim.opt.wrap = false
	end,
})
