local bind_close_buffer = function(key, buff, win)
	vim.keymap.set("n", key, function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buff })
end

return {
	"rmagatti/goto-preview",
	event = "BufEnter",
	config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
	dependencies = {
		{ "rmagatti/logger.nvim" },
	},
	opts = {
		width = 130,
		height = 22,
		post_open_hook = function(buff, win)
			-- Resize preview buffer
			vim.keymap.set("n", "<C-right>", "<C-w>>", { buffer = true })
			vim.keymap.set("n", "<C-left>", "<C-w><", { buffer = true })
			vim.keymap.set("n", "<C-up>", "<C-w>-", { buffer = true })
			vim.keymap.set("n", "<C-down>", "<C-w>+", { buffer = true })

			-- Bind multiple keys to close one buffer at a time
			bind_close_buffer("<Esc>", buff, win)
			bind_close_buffer("q", buff, win)
		end,
	},
	keys = {
		{
			"gp",
			function()
				require("goto-preview").goto_preview_definition()
			end,
			desc = "Goto Preview Definition",
		},
	},
}
