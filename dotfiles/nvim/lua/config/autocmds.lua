-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable document_color to prevent assertion crash when conform.nvim applies text edits
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.lsp.document_color.enable(false, { bufnr = args.buf })
	end,
})

-- Disable spell-checking in markdown
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.spell = false
	end,
})

-- Inlay hints only in normal mode: each hint request forces full type
-- inference of the visible range, which backs up tsserver while typing
local hints_paused = {}
vim.api.nvim_create_autocmd("InsertEnter", {
	callback = function(args)
		if vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }) then
			hints_paused[args.buf] = true
			vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
		end
	end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
	callback = function(args)
		if hints_paused[args.buf] then
			hints_paused[args.buf] = nil
			vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
		end
	end,
})
