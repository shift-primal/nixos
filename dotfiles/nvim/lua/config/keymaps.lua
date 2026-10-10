-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local function resolve_biome(root)
	local node_modules = vim.fs.find("node_modules", { upward = true, path = root, type = "directory" })[1]
	if node_modules then
		local local_bin = vim.fs.joinpath(node_modules, ".bin", "biome")
		if vim.fn.executable(local_bin) == 1 then
			return local_bin
		end
	end
	return "biome"
end

vim.keymap.set("n", "<leader>cB", function()
	local cwd = vim.fn.getcwd()
	Snacks.terminal.open(resolve_biome(cwd) .. " check .", { cwd = cwd, auto_close = false })
end, { desc = "Biome Check (project)" })
