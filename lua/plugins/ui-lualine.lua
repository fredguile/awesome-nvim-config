return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = {
				component_separators = "|",
				always_divide_middle = true,
			},
			sections = {
				lualine_y = {
					{
						"harpoon2",
						indicators = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
						active_indicators = { "[1]", "[2]", "[3]", "[4]", "[5]", "[6]", "[7]", "[8]", "[9]" },
					},
				},
			},
		},
	},
}
