local filetypes = {
	{ text = "markdown" },
	{ text = "javascript" },
	{ text = "javascriptreact" },
	{ text = "lua" },
	{ text = "python" },
	{ text = "typescript" },
	{ text = "typescriptreact" },
}

local function get_git_root_directory(path)
	local function is_git_repo(dir)
		local git_dir = dir .. "/.git"
		local stat = vim.loop.fs_stat(git_dir)
		return stat and stat.type == "directory"
	end

	local function get_parent_directory(dir)
		return vim.fn.fnamemodify(dir, ":h")
	end

	local directories = {}
	local current_dir = path
	while current_dir do
		table.insert(directories, current_dir)
		if is_git_repo(current_dir) then
			break
		end
		local parent_dir = get_parent_directory(current_dir)
		if parent_dir == current_dir then
			break
		end
		current_dir = parent_dir
	end

	return directories
end

local function list_directories_from_buffer()
	local current_buffer_path = vim.fn.expand("%:p:h")
	local directories = get_git_root_directory(current_buffer_path)
	return directories
end

local grep_current_buffer_dirs = function()
	-- Get a list of all parent directories of the current buffer (up to the git root)
	local directories = list_directories_from_buffer()

	-- Present the directories to the user for selection
	vim.ui.select(directories, {
		prompt = "Select directory to Grep:",
		format_item = function(item)
			return item
		end,
	}, function(choice)
		if choice then
			Snacks.picker.grep({ dirs = { choice } })
		else
			print("No directory selected")
		end
	end)
end

return {
	"folke/snacks.nvim",
	enabled = true,
	opts = {
		picker = {
			layout = {
				preset = "telescope",
			},
			formatters = {
				file = {
					truncate = 70,
				},
			},
			win = {
				list = {
					keys = {
						["<A-->"] = "edit_split",
					},
				},
			},
		},
		input = {
			win = {
				border = vim.g.borderStyle,
				keys = { q = "close" },
			},
		},
	},
	keys = {
		-- Disable defaults
		{ "<leader><space>", false },
		{ "<leader>.", false },
		{ "<leader>S", false },

		-- Picker
		{
			"<F5>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<C-p>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>.",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Grep word under cursor",
		},
		{
			"<leader>E",
			function()
				Snacks.explorer()
			end,
			desc = "Show explorer",
		},
		{
			"<leader>gt",
			function()
				Snacks.picker.git_status()
			end,
			desc = "List modified git files",
		},
		{
			"<leader><leader>g",
			function()
				Snacks.picker.git_status()
			end,
			desc = "List modified git files",
		},
		{
			"<leader><leader>b",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Open buffers",
		},
		{
			"<leader><leader>r",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent files",
		},

		-- Custom Pickers: Search open buffers
		{ "<leader>sx", grep_current_buffer_dirs, desc = "Grep (current Buffer Dirs)" },

		-- Custom Pickers: List modified files in current branch
		{
			"<leader>gm",
			function()
				-- ----- helpers -----
				local function git_root()
					local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
					if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
						return out[1]
					end
					return vim.loop.cwd()
				end

				local function run_git(args)
					local root = git_root()
					local cmd = { "git", "-C", root }
					vim.list_extend(cmd, args)
					local out = vim.fn.systemlist(cmd)
					return (vim.v.shell_error == 0) and out or {}
				end

				local function resolve_base_branch()
					local candidates = {
						"origin/main",
						"main",
						"origin/master",
						"master",
						"origin/develop",
						"develop",
					}

					for _, ref in ipairs(candidates) do
						-- Check if the ref exists
						local ok = vim.fn.system({ "git", "rev-parse", "--verify", ref })
						if vim.v.shell_error == 0 then
							-- Now make sure there's a valid merge-base
							local mb = vim.fn.systemlist({ "git", "merge-base", "HEAD", ref })[1]
							if mb and mb ~= "" then
								return ref
							end
						end
					end

					return "HEAD~" -- fallback
				end

				local function merge_base(base)
					local out = run_git({ "merge-base", "HEAD", base })
					if out[1] and out[1] ~= "" then
						return out[1]
					end
					return nil
				end

				local function get_changed_files(opts)
					opts = opts or {}
					local include_untracked = opts.include_untracked ~= false -- default true

					local base = resolve_base_branch()
					local mb = merge_base(base) or base

					-- NOTE: no --relative, and we always run at repo root with -C
					local committed = run_git({ "diff", "--name-only", "--diff-filter=ACMRTUXB", mb .. "..HEAD" })
					local staged = run_git({ "diff", "--name-only", "--diff-filter=ACMRTUXB", "--cached" })
					local unstaged = run_git({ "diff", "--name-only", "--diff-filter=ACMRTUXB" })
					local untracked = include_untracked and run_git({ "ls-files", "--others", "--exclude-standard" })
						or {}

					local root = git_root()
					local seen, items = {}, {}
					local function add(list)
						for _, p in ipairs(list) do
							if p ~= "" and not seen[p] then
								seen[p] = true
								local abs = root .. "/" .. p
								table.insert(items, { text = p, file = abs })
							end
						end
					end

					add(committed)
					add(staged)
					add(unstaged)
					add(untracked)
					return items
				end
				-- ----- /helpers -----

				local items = get_changed_files({ include_untracked = true })
				if vim.tbl_isempty(items) then
					vim.notify("No changes vs base", vim.log.levels.INFO)
					return
				end

				local Snacks = require("snacks")
				Snacks.picker({
					title = "Changed vs main",
					items = items,
					format = function(item)
						return { { item.text } }
					end, -- show repo-root-relative path
					confirm = function(picker, item)
						picker:close()
						picker:norm(function()
							vim.cmd.edit(vim.fn.fnameescape(item.file))
						end)
					end,
					actions = {
						["ctrl-v"] = function(picker, item)
							picker:close()
							picker:norm(function()
								vim.cmd.vsplit(vim.fn.fnameescape(item.file))
							end)
						end,
						["ctrl-x"] = function(picker, item)
							picker:close()
							picker:norm(function()
								vim.cmd.split(vim.fn.fnameescape(item.file))
							end)
						end,
					},
				})
			end,
			desc = "Files Changed vs main",
		},
		-- Scratch
		{
			"<F9>",
			function()
				require("utils.snacks.scratch").new_scratch(filetypes)
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<F10>",
			function()
				require("utils.snacks.scratch").select_scratch()
			end,
			desc = "Select Scratch Buffer",
		},
	},
}
