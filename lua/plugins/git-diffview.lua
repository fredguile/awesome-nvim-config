return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff View" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory<CR>", desc = "Diff File History" },
		},
	},
}
