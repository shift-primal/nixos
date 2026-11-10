-- astro-ls needs TypeScript <= 6 (TS 7 has no tsserverlibrary.js); fall back to the
-- TS 6 bundled with Nix's astro-ls when the project's TS is missing or too new
local function bundled_tsdk()
	local exe = vim.uv.fs_realpath(vim.fn.exepath("astro-ls"))
	if not exe then
		return nil
	end
	local root = vim.fs.dirname(vim.fs.dirname(exe))
	local pattern = root .. "/lib/node_modules/astro-language-server/node_modules/.pnpm/typescript@*/node_modules/typescript/lib"
	return vim.fn.glob(pattern, false, true)[1]
end

return {
	mason = false,
	settings = {
		emmet = { showExpandedAbbreviation = "never" },
	},

	before_init = function(_, config)
		local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
		if tsdk == "" or vim.fn.filereadable(tsdk .. "/tsserverlibrary.js") == 0 then
			tsdk = bundled_tsdk()
		end
		config.init_options = config.init_options or {}
		config.init_options.typescript = config.init_options.typescript or {}
		config.init_options.typescript.tsdk = tsdk
	end,
}
