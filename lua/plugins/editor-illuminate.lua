return {
	-- Highlight all instances of the word under the cursor
	"RRethy/vim-illuminate",
	enabled = true,
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		-- Performance: disable for large files and certain filetypes
		large_file_cutoff = 2000, -- Disable for files > 2000 lines
		filetypes_denylist = {
			"dirvish",
			"fugitive",
			"help",
			"lazy",
			"NvimTree",
			"oil",
		},
	},

	-- Override folke's default config to add centering!
	-- @see https://github.com/LazyVim/LazyVim/blob/12818a6cb499456f4903c5d8e68af43753ebc869/lua/lazyvim/plugins/extras/editor/illuminate.lua#L25
	config = function(_, opts)
		require("illuminate").configure(opts)

		local function map(key, dir, buffer)
			vim.keymap.set("n", key, function()
				require("illuminate")["goto_" .. dir .. "_reference"](false)

				-- center screen
				vim.cmd("normal! zz")
			end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
		end

		map("]]", "next")
		map("[[", "prev")

		-- also set it after loading ftplugins, since a lot overwrite [[ and ]]
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				local buffer = vim.api.nvim_get_current_buf()
				map("]]", "next", buffer)
				map("[[", "prev", buffer)
			end,
		})
	end,
}
