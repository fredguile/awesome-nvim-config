return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			-- mark_branch = true,   -- Scope marks to git branches
		},
		keys = function()
			local keys = {
				{
					"<leader>h",
					function()
						require("harpoon"):list():add()

						local fileName = vim.fn.expand("%:t")
						vim.notify('Added "' .. fileName .. '"', vim.log.levels.INFO, {
							title = "Harpoon",
						})
					end,
					desc = "Harpoon File",
				},
				{
					"<leader>`",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "Harpoon Quick Menu",
				},
			}

			for i = 1, 8 do
				table.insert(keys, {
					"<leader>" .. i,
					function()
						require("harpoon"):list():select(i)
					end,
					desc = "Harpoon to File " .. i,
				})
			end
			return keys
		end,
	},

	-- Harpoon lua line indicator with pretty icon
	{
		"letieu/harpoon-lualine",
		dependencies = {
			{
				"ThePrimeagen/harpoon",
				branch = "harpoon2",
			},
		},
	},
}
