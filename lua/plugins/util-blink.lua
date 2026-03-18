-- Allows extra capabilities provided by blink.cmp
return {
	"saghen/blink.cmp",
	opts = {
		keymap = {
			preset = "default",

			-- Accept the currently selected item
			["<Tab>"] = { "accept", "fallback" },

			-- Navigate forward / backward
			["<S-j>"] = { "select_next", "fallback" },
			["<S-k>"] = { "select_prev", "fallback" },

			-- Jump five items forward or backward in the list
			["<C-j>"] = {
				function(cmp)
					return cmp.select_next({ count = 5 })
				end,
				"fallback",
			},
			["<C-k>"] = {
				function(cmp)
					return cmp.select_prev({ count = 5 })
				end,
				"fallback",
			},
		},
		completion = {
			documentation = {
				auto_show = false,
				auto_show_delay_ms = 500,
				update_delay_ms = 150, -- Increased from default 50ms to prevent race conditions
				treesitter_highlighting = false, -- Disabled to prevent performance-related window issues
				window = {
					scrollbar = false, -- Disable scrollbar to simplify window management
				},
			},
		},
	},
}
