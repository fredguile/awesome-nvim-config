-- Python LSP support via basedpyright + ruff
-- Supports both poetry and uv virtual environments.
--
-- Tools installed via Mason:
--   basedpyright  — LSP (type checking, go-to-def, completions, etc.)
--   ruff          — formatter + linter (replaces black, isort, flake8)
--
-- Formatting is handled by conform.nvim (see editor-conform.lua).
-- Linting is handled by nvim-lint (see editor-lint.lua).

local function find_python(root)
	-- 1. Explicit VIRTUAL_ENV set in the shell
	if vim.env.VIRTUAL_ENV then
		local bin = vim.env.VIRTUAL_ENV .. "/bin/python"
		if vim.fn.executable(bin) == 1 then
			return bin
		end
	end

	-- 2. .venv inside the project root (uv default, poetry default with config)
	if root then
		for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python", ".env/bin/python" }) do
			local candidate = root .. "/" .. rel
			if vim.fn.executable(candidate) == 1 then
				return candidate
			end
		end
	end

	-- 3. Ask `poetry` for its env python
	if root and vim.fn.executable("poetry") == 1 then
		local result = vim.fn.system({ "poetry", "-C", root, "env", "info", "--executable" })
		if vim.v.shell_error == 0 then
			local path = vim.trim(result)
			if path ~= "" and vim.fn.executable(path) == 1 then
				return path
			end
		end
	end

	-- 4. Ask `uv` for its env python
	if root and vim.fn.executable("uv") == 1 then
		local result = vim.fn.system({ "uv", "python", "find" })
		if vim.v.shell_error == 0 then
			local path = vim.trim(result)
			if path ~= "" and vim.fn.executable(path) == 1 then
				return path
			end
		end
	end

	-- 5. Fall back to whatever python3 is on PATH
	if vim.fn.executable("python3") == 1 then
		return vim.fn.exepath("python3")
	end

	return vim.fn.exepath("python")
end

return {
	-- Dummy plugin entry — actual LSP wiring happens via lspconfig.lua's
	-- mason-lspconfig handler. We use this file purely to:
	--   a) install the Mason tools
	--   b) override basedpyright's lspconfig setup with venv-awareness
	"neovim/nvim-lspconfig",
	ft = { "python" },
	opts = function()
		-- Resolve project root and python interpreter at attach time
		local lspconfig = require("lspconfig")
		local util = lspconfig.util

		lspconfig.basedpyright.setup({
			root_dir = util.root_pattern(
				"pyproject.toml",
				"setup.cfg",
				"setup.py",
				"requirements.txt",
				".git"
			),
			before_initialize = function(params)
				-- Pass the venv python to the server before it starts
				local root = params.rootPath or params.rootUri and vim.uri_to_fname(params.rootUri)
				params.initializationOptions = params.initializationOptions or {}
				params.initializationOptions.pythonPath = find_python(root)
			end,
			settings = {
				basedpyright = {
					analysis = {
						-- "basic" | "standard" | "strict" | "off"
						typeCheckingMode = "standard",
						-- Let ruff handle unused-import / unused-variable diagnostics
						ignore = { "*" },
						diagnosticSeverityOverrides = {
							reportUnusedImport = "none",
							reportUnusedVariable = "none",
						},
					},
				},
			},
			-- Disable basedpyright's built-in formatter; ruff handles it
			on_attach = function(client, _)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end,
		})

		-- Return empty opts so we don't double-configure nvim-lspconfig
		return {}
	end,
}
