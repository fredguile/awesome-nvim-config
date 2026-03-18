return {
	-- Split/Join lines
	{
		"Wansmer/treesj",
		cond = true,
		keys = {
			{
				"<leader>j",
				function()
					require("treesj").toggle()
				end,
				desc = "Toggle Split/Join lines",
			},
		},
		opts = {
			use_default_keymaps = false,
			cursor_behavior = "start",
			max_join_length = 200,
		},
	},
}
