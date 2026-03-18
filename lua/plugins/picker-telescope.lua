return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-telescope/telescope-live-grep-args.nvim" },
			{ "nvim-telescope/telescope-symbols.nvim" },
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		opts = function(_, opts)
			local actions = require("telescope.actions")
			local layout = require("telescope.actions.layout")
			local trouble = require("trouble.sources.telescope")
			local lga_actions = require("telescope-live-grep-args.actions")

			opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
				preview = {
					filesize_limit = 0.1, -- Ignore preview for files larger than 100kb
				},
				prompt_prefix = "   ",
				selection_caret = " ",
				path_display = { "smart" },
				mappings = {
					i = {
						["<C-u>"] = false, -- Mapping <C-u> to clear prompt
						["<C-t>"] = trouble.open, -- Open with Trouble
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-p>"] = layout.toggle_preview,
						["<C-x>"] = false, -- Free for other plugins (e.g. codecompanion-history delete)
						["<C-Down>"] = actions.cycle_history_next,
						["<C-Up>"] = actions.cycle_history_prev,
						["<C-Space>"] = actions.to_fuzzy_refine, -- Start a fuzzy search in the frozen list
						["<Esc>"] = actions.close,
						["<C-h>"] = actions.which_key,
					},
					n = {
						["<c-t>"] = trouble,
					},
				},
			})
			opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
				lsp_definitions = {
					on_complete = {
						function(_)
							print("on complete!")
						end,
					},
				},
				oldfiles = {
					prompt_title = "Recent files",
					only_cwd = true,
					theme = "dropdown",
					previewer = false,
					layout_config = {
						width = 200,
					},
				},
			})
			opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				live_grep_args = {
					auto_quoting = true,
					additional_args = function()
						return { "--smart-case" }
					end,
					mappings = {
						i = {
							["<C-w>"] = lga_actions.quote_prompt(),
							["<C-q>"] = lga_actions.quote_prompt({ postfix = " -t " }),
							["<C-y>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
						},
					},
				},
			})
		end,
	},
}
