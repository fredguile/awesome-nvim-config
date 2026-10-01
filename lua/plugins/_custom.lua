return {
	-- Install plugins (with no config)
	{ "lbrayner/vim-rzip" }, -- Required for Yarn PnP
	{ "linrongbin16/gitlinker.nvim", cmd = "GitLink", opts = {} }, -- Open git files remotely
	{ "sitiom/nvim-numbertoggle" }, -- Relative numbers on only for current buffer in Normal mode
	{ "chrisgrieser/nvim-early-retirement", config = true, event = "VeryLazy" }, -- Auto-close inactive buffers
	{ "navarasu/onedark.nvim" },
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl" },

	-- Disable Plugins
	{ "windwp/nvim-autopairs", enabled = false }, -- Conflicts with mini.pairs (duplicate autopair, caused backtick bug in pickers)
	{ "nvim-neo-tree/neo-tree.nvim", enabled = false }, -- Replaced with mini.files
	{ "akinsho/bufferline.nvim", enabled = false }, -- Disable buffer tabs
	{ "lukas-reineke/indent-blankline.nvim", enabled = false },
	{ "folke/flash.nvim", enabled = false }, -- Disable flash; go all in on hop
	{ "SmiteshP/nvim-navic", enabled = false }, -- Disable LSP code context in statusline
	{ "nvim-mini/mini.diff", enabled = false }, -- Conflicts with gitsigns (folk's config)
}
