return {
	-- `hop` is an EasyMotion-like plugin allowing you to jump anywhere in a
	-- document with as few keystrokes as possible.
	{
		"smoka7/hop.nvim",
		version = "*",
		main = "hop",
		cond = true,
		opts = {
			multi_windows = true,
		},
		keys = function()
			local hop = require("hop")
			local directions = require("hop.hint").HintDirection

			local keys = {
				{ "sc", "<cmd>HopCamelCase<cr>", desc = "Hop to word", mode = { "n", "v", "x", "o" } },
				{ "ss", "<cmd>HopWord<cr>", desc = "Hop to word", mode = { "n", "v", "x", "o" } },
				{
					"sl",
					"<cmd>HopWordCurrentLine<cr>",
					desc = "Hop to word on current line",
					mode = { "n", "v", "x", "o" },
				},
				{ "sn", "<cmd>HopNodes<cr>", desc = "Hop to tree node", mode = { "n", "v", "x", "o" } },
				{ "s0", "<cmd>HopLine<cr>", desc = "Hop to line", mode = { "n", "v", "x", "o" } },
				{ "s_", "<cmd>HopLineStart<cr>", desc = "Hop to line start", mode = { "n", "v", "x", "o" } },
				{ "s/", "<cmd>HopPattern<cr>", desc = "Hop to pattern", mode = { "n", "v", "x", "o" } },
				{
					"se",
					function()
						hop.hint_words({ hint_position = require("hop.hint").HintPosition.END })
					end,
					desc = "Hop to word ends",
					mode = { "n", "v", "x", "o" },
				},

				-- Override t/T and f/F to search current line using Hop
				{
					"f",
					function()
						hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
					end,
					desc = "Hop after next char",
					mode = { "n", "v", "x", "o" },
				},
				{
					"F",
					function()
						hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
					end,
					desc = "Hop after prev char",
					mode = { "n", "v", "x", "o" },
				},
				{
					"t",
					function()
						hop.hint_char1({
							direction = directions.AFTER_CURSOR,
							current_line_only = true,
							hint_offset = -1,
						})
					end,
					desc = "Hop before next char",
					mode = { "n", "v", "x", "o" },
				},
				{
					"T",
					function()
						hop.hint_char1({
							direction = directions.BEFORE_CURSOR,
							current_line_only = true,
							hint_offset = 1,
						})
					end,
					desc = "Hop before prev char",
					mode = { "n", "v", "x", "o" },
				},
			}
			return keys
		end,
	},
}
