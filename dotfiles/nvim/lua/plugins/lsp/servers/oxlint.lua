local OXLINT = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
local OTHER = {
	"biome.json",
	"biome.jsonc",
	".biome.json",
	".biome.jsonc",
	"eslint.config.js",
	"eslint.config.cjs",
	"eslint.config.mjs",
	"eslint.config.ts",
	"eslint.config.mts",
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.json",
	".eslintrc.yaml",
	".eslintrc.yml",
}

return {
	mason = false,
	cmd = function(dispatchers, config)
		local root = (config or {}).root_dir
		local exe = root and vim.fs.joinpath(root, "node_modules/.bin/oxlint")
		if not exe or vim.fn.executable(exe) == 0 then
			exe = "oxlint"
		end
		return vim.lsp.rpc.start({ exe, "--lsp" }, dispatchers)
	end,
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, OXLINT)
		if not root then
			if vim.fs.root(bufnr, OTHER) then
				return
			end
			root = vim.fs.root(bufnr, { "package.json", ".git" }) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
		end
		on_dir(root)
	end,
	before_init = function(init_params, config)
		local settings = vim.deepcopy(config.settings or {})
		if not vim.fs.root(config.root_dir, OXLINT) then
			settings.configPath = vim.fs.normalize("~/.config/oxc/oxlintrc.json")
		end
		init_params.initializationOptions = { settings = settings }
	end,
}
