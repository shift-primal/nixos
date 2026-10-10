-- Nix provides the language servers, formatters, and debug adapters.
-- Mason must not install its own copies or prepend them to PATH.

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
	{
		"mason-org/mason.nvim",
		opts = {
			PATH = "skip",
		},
		config = function(_, opts)
			opts.ensure_installed = nil
			require("mason").setup(opts)
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		opts = {
			automatic_installation = false,
			ensure_installed = {},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			for name, server in pairs(opts.servers) do
				if name ~= "*" then
					if type(server) ~= "table" then
						server = {}
						opts.servers[name] = server
					end
					server.mason = false
				end
			end

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
