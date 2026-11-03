vim.opt.list = false
vim.opt.winborder = "rounded"
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
