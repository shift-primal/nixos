-- Decides per buffer whether the project opted into the Oxc toolchain.
-- Biome is the default; an ox config file at the project root flips it.
local M = {}

local FMT = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
local LINT = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }

---@param bufnr integer
function M.fmt_root(bufnr)
	return vim.fs.root(bufnr, FMT)
end

---@param bufnr integer
function M.lint_root(bufnr)
	return vim.fs.root(bufnr, LINT)
end

--- true if either ox config exists, i.e. biome should stay out of the way
---@param bufnr integer
function M.active(bufnr)
	return M.fmt_root(bufnr) ~= nil or M.lint_root(bufnr) ~= nil
end

return M
