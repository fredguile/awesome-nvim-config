return {
	"okuuva/auto-save.nvim",
	cmd = "ASToggle", -- optional for lazy loading on command
	event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
	opts = {
		-- Override default auto-save functionality and exclude other conflicting plugins
		condition = function(buf)
			local fn = vim.fn
			local utils = require("auto-save.utils.data")

			-- don't save for special-buffers
			if fn.getbufvar(buf, "&buftype") ~= "" then
				return false
			end

			if
				fn.getbufvar(buf, "&modifiable") == 1
				and utils.not_in(fn.getbufvar(buf, "&filetype"), { "harpoon", "TelescopePrompt" })
			then
				return true -- met condition(s), can save
			end
			return false -- can't save
		end,

		-- Disable auto-commands to avoid cyclic behaviour with auto-save/auto-format
		noautocmd = true,
		debounce_delay = 2000,
	},
}
