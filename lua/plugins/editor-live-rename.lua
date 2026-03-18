return {
	"saecki/live-rename.nvim",
	enabled = false,
	keys = {
		{
			"gR",
			function()
				require("live-rename").rename()
			end,
			desc = "Rename",
		},
	},
}
