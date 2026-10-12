-- Oxc is the default JS/TS toolchain. Per buffer, pick whose config wins:
-- a project ox config, a Vite+ (vp) config, or the global fallback in
-- ~/.config/oxc (dotfiles/oxc, linked by home/dotfiles.nix).
local M = {}

local FMT = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
local LINT = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
local VITE = { "vite.config.ts", "vite.config.mts", "vite.config.js", "vite.config.mjs" }

local global_dir = vim.fs.joinpath(vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(vim.env.HOME, ".config"), "oxc")
M.global_fmt = vim.fs.joinpath(global_dir, "oxfmtrc.json")
M.global_lint = vim.fs.joinpath(global_dir, "oxlintrc.json")

---@param path string
---@param field string
local function vite_has(path, field)
	local f = io.open(path, "r")
	if not f then
		return false
	end
	local text = f:read("*a")
	f:close()
	return text:find("vite%-plus") ~= nil and text:find(field .. "%s*:") ~= nil
end

---@param bufnr integer
---@param field "fmt"|"lint"
local function vp_root(bufnr, field)
	local root = vim.fs.root(bufnr, VITE)
	if not root then
		return nil
	end
	for _, name in ipairs(VITE) do
		if vite_has(vim.fs.joinpath(root, name), field) then
			return root
		end
	end
end

--- root of a Vite+ project that configures `fmt`; vp reads it, plain oxfmt cannot
---@param bufnr integer
function M.vp_fmt_root(bufnr)
	return vp_root(bufnr, "fmt")
end

---@param bufnr integer
function M.vp_lint_root(bufnr)
	return vp_root(bufnr, "lint")
end

--- nearest project oxfmt config; nil means the global one applies
---@param bufnr integer
function M.fmt_root(bufnr)
	return vim.fs.root(bufnr, FMT)
end

---@param bufnr integer
function M.lint_root(bufnr)
	return vim.fs.root(bufnr, LINT)
end

--- true if `root` itself holds an oxlint or vp `lint` config
---@param root string
function M.has_lint_config(root)
	for _, name in ipairs(LINT) do
		if vim.uv.fs_stat(vim.fs.joinpath(root, name)) then
			return true
		end
	end
	for _, name in ipairs(VITE) do
		if vite_has(vim.fs.joinpath(root, name), "lint") then
			return true
		end
	end
	return false
end

--- the project-local oxlint: plain install, else the one Vite+ bundles
---@param root string
function M.local_oxlint(root)
	for _, rel in ipairs({ "node_modules/.bin/oxlint", "node_modules/vite-plus/node_modules/.bin/oxlint" }) do
		local exe = vim.fs.joinpath(root, rel)
		if vim.fn.executable(exe) == 1 then
			return exe
		end
	end
end

return M
