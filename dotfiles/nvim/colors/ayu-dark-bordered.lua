-- ayu-dark, with the "bordered" treatment from the ayu-dark-bordered VS Code
-- theme (teabyii.ayu): every UI seam — window splits and float borders alike —
-- drawn with one consistent border color instead of left to blend into bg.
-- Actual border color/highlights live in the `shatur/neovim-ayu` overrides
-- (lua/plugins/ui/colorscheme.lua), so this file only has to pick the base.
vim.o.background = "dark"
require("ayu.config").mirage = false
require("ayu").colorscheme()
