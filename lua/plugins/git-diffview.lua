return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff View" },
			{ "<leader>ga", "<cmd>DiffviewToggleFiles<CR>", desc = "Diff Toggle Files" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory<CR>", desc = "Diff File History" },
		},
	},
}
