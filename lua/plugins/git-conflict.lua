return {
	"akinsho/git-conflict.nvim",
	lazy = false,
	config = function()
		local git_conflict = require("git-conflict")

		git_conflict.setup({
			default_mappings = true,
			default_commands = true,
			list_opener = "copen",
			highlights = { -- They must have background color, otherwise the default color will be used
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})

		local group = vim.api.nvim_create_augroup("GitConflictRefresh", { clear = true })
		local function refresh_and_clear(bufnr)
			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				pcall(git_conflict.clear, bufnr)
			end
			if vim.fn.exists(":GitConflictRefresh") == 2 then
				vim.cmd("silent! GitConflictRefresh")
			end
		end

		vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete" }, {
			group = group,
			callback = function(args)
				refresh_and_clear(args.buf)
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = { "DiffviewFileOpened", "DiffviewPanelTOGGLE" },
			callback = function()
				vim.schedule(function()
					local buf = vim.api.nvim_get_current_buf()
					if vim.api.nvim_buf_is_valid(buf) then
						pcall(git_conflict.clear, buf)
					end
				end)
			end,
		})
	end,
}

