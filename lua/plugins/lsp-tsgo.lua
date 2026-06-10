local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
local tsgo_bin = vim.fs.joinpath(mason_bin, "tsgo")

return {
	{
		"neovim/nvim-lspconfig",
		ft = {
			"typescript",
			"javascript",
			"typescriptreact",
			"javascriptreact",
		},
		config = function()
			if vim.fn.executable(tsgo_bin) ~= 1 then
				vim.notify(
					"tsgo not found at " .. tsgo_bin .. ". Install via :Mason (tsgo)",
					vim.log.levels.WARN
				)
				return
			end

			require("lspconfig.configs").tsgo = {
				default_config = {
					cmd = { tsgo_bin, "--lsp", "--stdio" },
					filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
					root_dir = function(fname)
						local util = require("lspconfig.util")
						-- Don't attach to special buffers
						if
							fname:match("^diffview://")
							or fname:match("^fugitive://")
							or fname:match("^gitsigns://")
							or fname:match("%.git/")
							or fname:match("^term://")
						then
							return nil
						end
						return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json")(fname)
							or util.find_git_ancestor(fname)
							or vim.fn.getcwd()
					end,
					single_file_support = true,
				},
			}

			require("lspconfig").tsgo.setup({})
		end,
	},
}
