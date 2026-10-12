local ox = require("config.ox")

-- Runs in every JS/TS buffer. A project .oxlintrc or vp `lint` config wins;
-- otherwise ~/.config/oxc/oxlintrc.json is passed as configPath.
return {
	mason = false,
	cmd = function(dispatchers, config)
		local root = (config or {}).root_dir
		local exe = root and ox.local_oxlint(root) or "oxlint"
		return vim.lsp.rpc.start({ exe, "--lsp" }, dispatchers)
	end,
	root_dir = function(bufnr, on_dir)
		local root = ox.lint_root(bufnr)
			or ox.vp_lint_root(bufnr)
			or vim.fs.root(bufnr, { "package.json", ".git" })
			or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
		on_dir(root)
	end,
	before_init = function(init_params, config)
		local settings = vim.deepcopy(config.settings or {})
		if not ox.has_lint_config(config.root_dir) then
			settings.configPath = ox.global_lint
		end
		init_params.initializationOptions = { settings = settings }
	end,
}
