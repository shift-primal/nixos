-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- the Nix biome, not node_modules/.bin/biome: that one is a generic-linux binary NixOS cannot run
vim.keymap.set("n", "<leader>cB", function()
	local cwd = vim.fn.getcwd()
	Snacks.terminal.open("biome check .", { cwd = cwd, auto_close = false })
end, { desc = "Biome Check (project)" })
