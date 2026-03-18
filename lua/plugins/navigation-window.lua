return {
	{
		"yorickpeterse/nvim-window",
		opts = {
			chars = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
		},
		keys = {
			{ ",", "<cmd>lua require('nvim-window').pick()<cr>", desc = "nvim-window: Jump to window" },
		},
	},
	{
		"sindrets/winshift.nvim",
		enabled = false,
		cmd = "WinShift",
		opts = {
			highlight_moving_win = true, -- Highlight the window being moved
			focused_hl_group = "Visual", -- The highlight group used for the moving window
			moving_win_options = {
				cursorline = false,
				cursorcolumn = false,
				colorcolumn = "",
			},
			picker_chars = "1234567890",
		},
		keys = {
			{ "<leader>mm", "<cmd>WinShift<cr>", desc = "Move window mode" },
			{ "<leader>ms", "<cmd>WinShift swap<cr>", desc = "Swap with window" },

			{ "<leader>mh", "<cmd>WinShift left<cr>", desc = "Move window left" },
			{ "<leader>mj", "<cmd>WinShift down<cr>", desc = "Move window down" },
			{ "<leader>mk", "<cmd>WinShift up<cr>", desc = "Move window up" },
			{ "<leader>ml", "<cmd>WinShift right<cr>", desc = "Move window right" },

			{ "<leader>mH", "<cmd>WinShift far_left<cr>", desc = "Move window far left" },
			{ "<leader>mJ", "<cmd>WinShift far_down<cr>", desc = "Move window far down" },
			{ "<leader>mK", "<cmd>WinShift far_up<cr>", desc = "Move window far up" },
			{ "<leader>mL", "<cmd>WinShift far_right<cr>", desc = "Move window far right" },
		},
	},
}
