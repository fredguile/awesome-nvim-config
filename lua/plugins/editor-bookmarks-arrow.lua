return {
	{
		"otavioschwanck/arrow.nvim",
		event = "VeryLazy",
		opts = {
			show_icons = true,
			always_show_path = true,
			separate_by_branch = true, -- Separate bookmarks for different git branches
			buffer_leader_key = "m",
			hide_handbook = true,
			window = {
				width = 130,
				col = 40,
			},
			per_buffer_config = {
				lines = 6,
			},
			leader_key = ";",
			separate_save_and_remove = true, -- Disable toggle when saving buffer to arrow
		},
	},
}
