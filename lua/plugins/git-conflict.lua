return {
	"akinsho/git-conflict.nvim",
	lazy = false,
	config = function()
		local git_conflict = require("git-conflict")
		local api = vim.api

		git_conflict.setup({
			default_mappings = true,
			default_commands = true,
			list_opener = "copen",
			highlights = {
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})

		local group = api.nvim_create_augroup("GitConflictRefresh", { clear = true })
		local function refresh_and_clear(bufnr)
			if bufnr and api.nvim_buf_is_valid(bufnr) then
				pcall(git_conflict.clear, bufnr)
			end
			if vim.fn.exists(":GitConflictRefresh") == 2 then
				vim.cmd("silent! GitConflictRefresh")
			end
		end

		api.nvim_create_autocmd({ "BufWritePost", "BufDelete" }, {
			group = group,
			callback = function(args)
				refresh_and_clear(args.buf)
			end,
		})

		api.nvim_create_autocmd("User", {
			pattern = { "DiffviewFileOpened", "DiffviewPanelTOGGLE" },
			callback = function()
				vim.schedule(function()
					local buf = api.nvim_get_current_buf()
					if api.nvim_buf_is_valid(buf) then
						pcall(git_conflict.clear, buf)
					end
					pcall(function()
						api.nvim_set_decoration_provider(git_conflict.NAMESPACE, {
							on_buf = function()
								return false
							end,
						})
					end)
				end)
			end,
		})

		api.nvim_create_autocmd("User", {
			pattern = { "DiffviewExit" },
			callback = function()
				vim.schedule(function()
					pcall(function()
						local utils = require("git-conflict.utils")
						api.nvim_set_decoration_provider(git_conflict.NAMESPACE, {
							on_buf = function(_, bufnr, _)
								return utils.is_valid_buf(bufnr)
							end,
							on_win = function(_, _, bufnr, _, _)
								if git_conflict.visited_buffers[bufnr] then
									git_conflict.process(bufnr)
								end
							end,
						})
					end)
				end)
			end,
		})
	end,
}

