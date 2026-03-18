local yank_history_telescope_cursor = function()
	require("telescope").extensions.yank_history.yank_history({
		layout_strategy = "cursor",
		layout_config = { width = 0.7, height = 20 },
	})
end

return {
	"gbprod/yanky.nvim",
	keys = {
		-- Disable Lazyvim defaults
		{ "gp", mode = { "n", "x" }, false },
		{ "gP", mode = { "n", "x" }, false },

		-- Add new mappings
		{ "<leader>p", yank_history_telescope_cursor, { desc = "Yank History Picker" } },
		{ "<C-r>", yank_history_telescope_cursor, mode = { "i" }, { desc = "Yank History Picker" } },
	},
}
