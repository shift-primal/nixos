-- Nix provides the language servers, formatters, and debug adapters.
-- Mason must not install its own copies or prepend them to PATH.

local function vue_plugin_location()
	local bin = vim.fn.exepath("vue-language-server")
	if bin == "" then
		return nil
	end
	local out = vim.fn.fnamemodify(vim.fn.resolve(bin), ":h:h")
	return out .. "/lib/language-tools/packages/language-server"
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
