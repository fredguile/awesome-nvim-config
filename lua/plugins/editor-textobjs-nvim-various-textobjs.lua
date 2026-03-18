return {
	{
		"chrisgrieser/nvim-various-textobjs",
		enabled = false,
		config = function()
			require("various-textobjs").setup({
				keymaps = {
					useDefaults = false,
				},
			})

			-- Sub word (text object for camel-case, words split by `-` or `_`)
			vim.keymap.set({ "o", "x" }, "iS", "<cmd>lua require('various-textobjs').subword('inner')<CR>")
			vim.keymap.set({ "o", "x" }, "aS", "<cmd>lua require('various-textobjs').subword('outer')<CR>")
			vim.keymap.set({ "o", "x" }, "iC", "<cmd>lua require('various-textobjs').subword('inner')<CR>")
			vim.keymap.set({ "o", "x" }, "aC", "<cmd>lua require('various-textobjs').subword('outer')<CR>")

			-- Key
			vim.keymap.set({ "o", "x" }, "ik", "<cmd>lua require('various-textobjs').key('inner')<CR>")
			vim.keymap.set({ "o", "x" }, "ak", "<cmd>lua require('various-textobjs').key('outer')<CR>")

			-- Value
			vim.keymap.set({ "o", "x" }, "iv", "<cmd>lua require('various-textobjs').value('inner')<CR>")
			vim.keymap.set({ "o", "x" }, "av", "<cmd>lua require('various-textobjs').value('outer')<CR>")

			-- Chain Member
			vim.keymap.set({ "o", "x" }, "im", "<cmd>lua require('various-textobjs').chainMember('inner')<CR>")
			vim.keymap.set({ "o", "x" }, "am", "<cmd>lua require('various-textobjs').chainMember('outer')<CR>")

			-- Indentation
			vim.keymap.set({ "o", "x" }, "ii", "<cmd>lua require('various-textobjs').indentation('inner', 'inner')<CR>")
			vim.keymap.set({ "o", "x" }, "ai", "<cmd>lua require('various-textobjs').indentation('outer', 'outer')<CR>")
		end,
	},
}
