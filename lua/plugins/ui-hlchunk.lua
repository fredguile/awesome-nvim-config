return {
	"shellRaining/hlchunk.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		line_num = {
			enable = true,
			use_treesitter = true,
			-- style = "#00ffff",
		},
		chunk = {
			use_treesitter = true,
			enable = true,
			chars = {
				horizontal_line = "─",
				vertical_line = "│",
				left_top = "┌",
				left_bottom = "└",
				right_arrow = "─",
			},
			-- style = "#00ffff",
		},
	},
}
