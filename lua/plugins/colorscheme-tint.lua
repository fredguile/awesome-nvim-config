return {
	"levouh/tint.nvim",
	-- enabled = false,
	keys = {},
	config = function(opts)
		local tint = require("tint")

		-- Toggle tint when focus lost away from nvim (e.g. tmux)
		vim.api.nvim_create_autocmd({ "FocusGained" }, {
			pattern = "*",
			callback = function()
				tint.enable()
			end,
		})
		vim.api.nvim_create_autocmd({ "FocusLost" }, {
			pattern = "*",
			callback = function()
				tint.disable()
			end,
		})

		tint.setup({
			tint = -45, -- Darken colors, use a positive value to brighten
			saturation = 0.5, -- Saturation to preserve
		})
	end,
}
