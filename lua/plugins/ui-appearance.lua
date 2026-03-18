return {
	{ -- scrollbar with information
		"lewis6991/satellite.nvim",
		event = "VeryLazy",
		opts = {
			winblend = 10, -- little transparency, since hard to see in many themes otherwise
			handlers = {
				cursor = { enable = false },
				marks = { enable = false }, -- prevents buggy mark mappings
				quickfix = { enable = true },
			},
		},
		config = function(_, opts)
			require("satellite").setup(opts)

			-- WORKAROUND:
			-- satellite.nvim installs a <LeftMouse> mapping for interactive dragging.
			-- On some window/tabpage transitions it can end up with a stale window id
			-- and crash (E5108: scoped variable: Invalid window id).
			-- Remove the mapping only if it looks like satellite.nvim installed it.
			--
			-- NOTE: We intentionally don't use vim.keymap.get() here for compatibility
			-- with older Neovim builds.
			for _, mode in ipairs({ "n", "v", "o", "i" }) do
				local map = vim.fn.maparg("<LeftMouse>", mode, false, true)
				-- maparg() returns an empty string when not mapped, otherwise a dict.
				if type(map) == "table" then
					local rhs = map.rhs or ""
					-- When satellite sets it, it becomes a <Lua ...> rhs that calls
					-- require('satellite.mouse').handle_leftmouse().
					if type(rhs) == "string" and rhs:find("satellite%.mouse", 1, false) then
						pcall(vim.keymap.del, mode, "<LeftMouse>")
					end
				end
			end
		end,
	},
}
