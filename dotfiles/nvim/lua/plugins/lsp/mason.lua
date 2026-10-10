-- Nix provides the language servers, formatters, and debug adapters
-- (~/nixos/home/dev). Mason is disabled entirely.

local function vue_plugin_location()
	local bin = vim.fn.exepath("vue-language-server")
	if bin == "" then
		return nil
	end
	local out = vim.fn.fnamemodify(vim.fn.resolve(bin), ":h:h")
	local location = out .. "/lib/language-tools/packages/language-server"
	if vim.fn.isdirectory(location) == 0 then
		return nil
	end
	return location
end

-- The Vue extra calls LazyVim.get_pkg_path("vue-language-server") while
-- building lspconfig opts. That looks under Mason and warns when the package
-- is absent. Return the Nix package so the lookup succeeds.
if LazyVim and type(LazyVim.get_pkg_path) == "function" then
	local get_pkg_path = LazyVim.get_pkg_path
	function LazyVim.get_pkg_path(pkg, path, opts)
		if pkg == "vue-language-server" then
			local location = vue_plugin_location()
			if location then
				return location
			end
		end
		return get_pkg_path(pkg, path, opts)
	end
end

return {
	-- LazyVim checks for these before using them, so it falls back to PATH.
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{ "jay-babu/mason-nvim-dap.nvim", enabled = false },
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			local location = vue_plugin_location()
			local plugins = vim.tbl_get(opts.servers, "vtsls", "settings", "vtsls", "tsserver", "globalPlugins")
			if location and type(plugins) == "table" then
				for _, plugin in ipairs(plugins) do
					if plugin.name == "@vue/typescript-plugin" then
						plugin.location = location
					end
				end
			end
		end,
	},
}
