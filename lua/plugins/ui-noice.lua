return {
	"folke/noice.nvim",
	opts = {
		presets = {
			lsp_doc_border = true,
		},
		cmdline = {
			format = {
				cmdline = { pattern = "^:", icon = "", lang = false },
				search_down = { kind = "search", pattern = "^/", icon = "", lang = false },
				search_up = { kind = "search", pattern = "^?", icon = "", lang = false },
				filter = { pattern = "^:%s*!", icon = "$", lang = false },
				lua = {
					pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
					icon = "",
					lang = false,
				},
				calculator = { pattern = "^=", icon = "", lang = false },
			},
		},
		lsp = {
			signature = {
				auto_open = {
					trigger = false,
				},
			},
		},
	},
}
