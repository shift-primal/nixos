-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.list = false

-- default border for every native floating window (LSP hover/signature,
-- diagnostics, :checkhealth, etc.) — plugins that don't hardcode their own
-- border (blink.cmp, noice, snacks) fall back to this too
vim.opt.winborder = "rounded"

-- only run prettier where it's explicitly configured, so it doesn't
-- double-format projects that use biome instead
vim.g.lazyvim_prettier_needs_config = true

vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 0

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 0
vim.opt.formatoptions:remove({ "t", "a" })

vim.opt.breakindent = true
vim.opt.breakindentopt = "list:-1"
vim.opt.formatlistpat = [[^\s*[-*+]\s\+\|^\s*\d\+[.\)]\s\+]]
