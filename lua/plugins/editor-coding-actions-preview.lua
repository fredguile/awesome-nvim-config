return {
	"aznhe21/actions-preview.nvim",
	event = "VeryLazy",
	-- enabled = false,
	opts = {
		telescope = vim.tbl_extend("force", require("telescope.themes").get_cursor(), {
			previewer = true,
			layout_config = {
				width = 0.5,
				height = 20,
			},
			resizing_mappings = true,
		}),
	},
	keys = {
		{
			"ga",
			function()
				require("actions-preview").code_actions()
			end,
			mode = { "n", "v" },
			desc = "Show Code Actions",
		},
	},
}
