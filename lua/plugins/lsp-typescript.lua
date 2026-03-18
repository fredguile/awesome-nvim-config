--- Determine the tsserver path
--- Prefer a local TypeScript installation (monorepos often rely on it).
--- We search upward from the current buffer directory (or cwd) for:
---   node_modules/typescript/lib/tsserver.js
--- @return string|nil - Path to tsserver.js if found, nil otherwise
local function get_tsserver_path()
	local util = require("lspconfig.util")
	local path = util.path

	local function find_from(start_dir)
		if not start_dir or start_dir == "" then
			return nil
		end
		return util.search_ancestors(start_dir, function(dir)
			local candidate = path.join(dir, "node_modules", "typescript", "lib", "tsserver.js")
			if vim.fn.filereadable(candidate) == 1 then
				return candidate
			end
		end)
	end

	local bufname = vim.api.nvim_buf_get_name(0)
	local bufdir = bufname ~= "" and vim.fs.dirname(bufname) or nil

	local tsserver_path = find_from(bufdir) or find_from(vim.fn.getcwd())
	if tsserver_path then
		vim.notify("Using custom tsserver path: " .. tsserver_path, vim.log.levels.INFO)
		return tsserver_path
	end

	-- Return nil to let the plugin resolve the path (global install, etc.)
	return nil
end

local function load_twoslash_queries()
	local ok, twoslash = pcall(require, "twoslash-queries")
	if ok then
		return twoslash
	end

	local lazy_ok, lazy = pcall(require, "lazy")
	if lazy_ok then
		lazy.load({ plugins = { "twoslash-queries.nvim" } })
		ok, twoslash = pcall(require, "twoslash-queries")
		if ok then
			return twoslash
		end
	end
end

return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig", "marilari88/twoslash-queries.nvim" },
	enabled = true,
	ft = {
		"typescript",
		"javascript",
		"typescriptreact",
		"javascriptreact",
	},
	config = function()
		local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
		local tls = vim.fs.joinpath(mason_bin, "typescript-language-server")
		local cmd
		if vim.fn.executable(tls) == 1 then
			cmd = { tls, "--stdio" }
		elseif vim.fn.executable("typescript-language-server") == 1 then
			cmd = { "typescript-language-server", "--stdio" }
		else
			-- This plugin only loads for TS/JS buffers (ft=...), so this warning should only show
			-- when opening TS/JS files.
			vim.notify(
				"TypeScript LSP not available: install 'typescript-language-server' via :Mason (or ensure it's on $PATH)",
				vim.log.levels.WARN
			)
		end

		require("typescript-tools").setup({
			cmd = cmd,
-- Prevent attachment to special buffers using root_dir
root_dir = function(fname)
-- Handle both string (filename) and number (bufnr) cases
local bufname
if type(fname) == "number" then
bufname = vim.api.nvim_buf_get_name(fname)
else
bufname = fname
end

-- Empty buffer name => just use cwd
if not bufname or bufname == "" then
return vim.fn.getcwd()
end

-- Don't attach to special buffer types
if bufname:match("^diffview://")
or bufname:match("^fugitive://")
or bufname:match("^gitsigns://")
or bufname:match("%.git/")
or bufname:match("^term://")
then
return nil -- Returning nil prevents LSP attachment
end

local util = require("lspconfig.util")
local path = util.path

-- Prefer a JS/TS project root.
-- (In monorepos there can be many nested package.json/tsconfig.json files.)
local root = util.root_pattern("tsconfig.json", "jsconfig.json", "package.json")(bufname)
or util.find_git_ancestor(bufname)

-- Fall back to the file's directory so the server still attaches.
if not root then
local dir = path.dirname(bufname)
root = (dir and dir ~= "") and dir or vim.fn.getcwd()
end

return root
end,
			on_attach = function(client, bufnr)
				local twoslash = load_twoslash_queries()
				if twoslash then
					twoslash.attach(client, bufnr)
				end
			end,
			settings = {
				-- spawn additional tsserver instance to calculate diagnostics on it
				separate_diagnostic_server = false,
				-- "change"|"insert_leave" determine when the client asks the server about diagnostic
				publish_diagnostic_on = "insert_leave",
				-- array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
				-- "remove_unused_imports"|"organize_imports") -- or string "all"
				-- to include all supported code actions
				-- specify commands exposed as code_actions
				expose_as_code_action = "all",
				-- string|nil - specify a custom path to `tsserver.js` file, if this is nil or file under path
				-- not exists then standard path resolution strategy is applied
				tsserver_path = get_tsserver_path(),
				-- specify a list of plugins to load by tsserver, e.g., for support `styled-components`
				-- (see 💅 `styled-components` support section)
				tsserver_plugins = {},
				-- this value is passed to: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes
				-- memory limit in megabytes or "auto"(basically no limit)
				-- Increased for large monorepos like atlassian-frontend-monorepo
				tsserver_max_memory = "auto",
				-- described below
				tsserver_format_options = {},
				tsserver_file_preferences = {
					-- includeInlayParameterNameHints = "all",
					-- includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					-- includeInlayFunctionParameterTypeHints = true,
					-- includeInlayVariableTypeHints = true,
					-- includeInlayPropertyDeclarationTypeHints = true,
					-- includeInlayFunctionLikeReturnTypeHints = true,
					-- includeInlayEnumMemberValueHints = true,
				},
				-- locale of all tsserver messages, supported locales you can find here:
				-- https://github.com/microsoft/TypeScript/blob/3c221fc086be52b19801f6e8d82596d04607ede6/src/compiler/utilitiesPublic.ts#L620
				tsserver_locale = "en",
				-- mirror of VSCode's `typescript.suggest.completeFunctionCalls`
				complete_function_calls = false,
				include_completions_with_insert_text = true,
				-- CodeLens
				-- WARNING: Experimental feature also in VSCode, because it might hit performance of server.
				-- possible values: ("off"|"all"|"implementations_only"|"references_only")
				code_lens = "off",
				-- by default code lenses are displayed on all referencable values and for some of you it can
				-- be too much this option reduce count of them by removing member references from lenses
				disable_member_code_lens = true,
				-- JSXCloseTag
				-- WARNING: it is disabled by default (maybe you configuration or distro already uses nvim-ts-autotag,
				-- that maybe have a conflict if enable this feature. )
				jsx_close_tag = {
					enable = false,
					filetypes = { "javascriptreact", "typescriptreact" },
				},
			},
		})
	end,
}
