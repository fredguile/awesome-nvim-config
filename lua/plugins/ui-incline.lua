return {
	"b0o/incline.nvim",
	event = "VeryLazy",
	config = function()
		require("incline").setup({
			ignore = {
				floating_wins = false,
			},
			render = function(props)
				-- Don't render anything if cursor is on the first line
				if props.win and vim.api.nvim_win_get_cursor(props.win)[1] == 1 then
					return {}
				end

				local ft = vim.bo[props.buf].filetype
				local bt = vim.bo[props.buf].buftype

				-- Hide overlay for non-file buffers and common “special” windows.
				-- (Safe defaults; extend this list as needed.)
				local ignored_filetypes = {
					["help"] = true,
					["qf"] = true,
					["TelescopePrompt"] = true,
					["Trouble"] = true,
					["trouble"] = true,
					["lazy"] = true,
					["mason"] = true,
					["neo-tree"] = true,
					["NvimTree"] = true,
					["oil"] = true,
					["harpoon"] = true,
				}

				if (bt and bt ~= "") or ignored_filetypes[ft] then
					return {}
				end

				local bufname = vim.api.nvim_buf_get_name(props.buf)
				local filename = vim.fn.fnamemodify(bufname, ":t")
				if filename == "" then
					filename = "[No Name]"
				end

				local parent_dir = vim.fn.fnamemodify(bufname, ":h:t")
				local label = (parent_dir ~= nil and parent_dir ~= "" and parent_dir ~= ".") and (parent_dir .. "/" .. filename)
					or filename

				local modified = vim.bo[props.buf].modified and "bold,italic" or "None"

				local filetype_icon, color = require("nvim-web-devicons").get_icon_color(filename)

				local render = {}
				if filetype_icon ~= nil then
					table.insert(render, { filetype_icon, guifg = color })
					table.insert(render, { " " })
				end
				table.insert(render, { label, gui = modified })
				return render
			end,
		})
	end,
}
