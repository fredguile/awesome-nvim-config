-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local M = {}

local LazyVim = require("lazyvim.util")
local telescope_builtin = require("telescope.builtin")

local has_snacks, Snacks = pcall(require, "snacks")

do
	local server = vim.v.servername
	if server ~= nil and server ~= "" then
		vim.env.NVIM = server
		vim.env.NVIM_LISTEN_ADDRESS = server
	end
end

-- local wk = require("which-key")

-- Custom keymap function that checks if a lazy keys handler exists before creating a keymap
-- @see https://github.com/aserowy/tmux.nvim/issues/92#issuecomment-1873710733
local function map(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys

	---@cast keys LazyKeysHandler
	-- do not create the keymap if a lazy keys handler exists
	if not keys.active[keys.parse({ lhs, mode = mode }).id] then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

local function toggle_it_only()
	local line = vim.api.nvim_get_current_line() -- Get the current line in the buffer
	-- If the line contains 'it.only', replace with `it`
	if line:match("^%s*it%.only%s*%(") then
		line = line:gsub("it%.only", "it")
	-- If line contains `it`, replace with `it.only`
	elseif line:match("^%s*it%s*%(") then
		-- Replace 'it' with 'it.only'
		line = line:gsub("it", "it.only", 1)
	else
		return
	end
	vim.api.nvim_set_current_line(line) -- Set the modified line back to the buffer
end

-- Delete global LazyVim keymaps
-- These may or may not exist depending on LazyVim version / enabled extras.
pcall(vim.keymap.del, { "n" }, "<leader>l")
pcall(vim.keymap.del, { "n" }, "<leader>L")


-- Duplicate line and comment first line
map("n", "ycc", "yygccp", { remap = true })

-- Window navigation
map("n", "<leader>w\\", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>w-", "<C-w>s", { desc = "Split horizontal" })

-- LazyVim distro keymaps
-- wk.add({ "<leader>L", group = "LazyVim" })
map("n", "<leader>Ll", "<cmd>Lazy<CR>", { desc = "lazy.nvim" })
map("n", "<leader>Lm", "<cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>Le", "<cmd>LazyExtras<CR>", { desc = "LazyVim Extras" })
map("n", "<leader>LL", function()
	LazyVim.news.changelog()
end, { desc = "lazy.nvim Changelog" })

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Navigate back and forth
map("n", "<C-[>", "<C-O>", { desc = "Navigate back" })
map("n", "<C-]>", "<C-I>", { desc = "Navigate forward" })

-- Switch back and forth between last 2 buffers
map("n", "ge", "<cmd>b#<CR>", { desc = "Switch back" })

-- Using change without yank
map({ "n", "v" }, "c", '"_c', { desc = "Change without yank" })
map({ "n", "v" }, "C", '"_C', { desc = "Change without yank" })

-- Using char delete without yank
map({ "n", "v" }, "x", '"_x', { desc = "Char delete without yank" })

-- Using delete without yank
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

-- Disable default `s` keybind - reusing it for `hop`
map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })

local function open_lazygit()
	local function normalize(path)
		return path and vim.fn.fnamemodify(path, ":p") or nil
	end

	local roots = {}
	local seen = {}

	local cwd = normalize(vim.loop.cwd())
	local git_root = normalize(LazyVim.root.git())

	if git_root then
		seen[git_root] = true
		roots[#roots + 1] = { label = "LazyGit (Git Root)", cwd = git_root }
	end

	if cwd and not seen[cwd] then
		seen[cwd] = true
		roots[#roots + 1] = { label = "LazyGit (CWD)", cwd = cwd }
	end

	if #roots == 0 then
		vim.notify("No working directory available for LazyGit", vim.log.levels.WARN)
		return
	end

	local cmd_line = "lazygit"

	local function launch(dir)
		if has_snacks and Snacks.lazygit then
			return Snacks.lazygit({
				cwd = dir,
				win = {
					style = "lazygit",
					title = "LazyGit",
					border = vim.g.borderStyle or "rounded",
					width = 0.94,
					height = 0.9,
				},
			})
		end

		vim.cmd("tabnew")
		if dir and dir ~= "" then
			vim.cmd("tcd " .. vim.fn.fnameescape(dir))
		end
		vim.cmd("terminal " .. cmd_line)
		vim.cmd("startinsert")

		local tabpage = vim.api.nvim_get_current_tabpage()
		local bufnr = vim.api.nvim_get_current_buf()
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = bufnr,
			once = true,
			callback = function()
				vim.defer_fn(function()
					if vim.api.nvim_buf_is_valid(bufnr) then
						vim.api.nvim_buf_delete(bufnr, { force = true })
					end
					if vim.api.nvim_tabpage_is_valid(tabpage) then
						pcall(vim.api.nvim_set_current_tabpage, tabpage)
						pcall(vim.cmd, "tabclose")
					end
				end, 20)
			end,
		})
	end

	if not has_snacks or #roots == 1 then
		return launch(roots[1].cwd)
	end

	return Snacks.picker({
		title = "LazyGit",
		items = roots,
		format = function(item)
			local rel = vim.fn.fnamemodify(item.cwd, ":~")
			return {
				{ item.label, "Title" },
				{ rel, "Comment" },
			}
		end,
		default = roots[1],
		confirm = function(picker, item)
			picker:close()
			picker:norm(function()
				launch(item.cwd)
			end)
		end,
	})
end

-- Override any existing mapping/command provided by LazyVim extras
pcall(vim.keymap.del, { "n" }, "<leader>gg")
pcall(vim.api.nvim_del_user_command, "LazyGit")
vim.api.nvim_create_user_command("LazyGit", open_lazygit, { desc = "Open Lazygit" })
-- Use vim.keymap.set directly to ensure we override LazyVim-provided mappings.
vim.keymap.set("n", "<leader>gg", open_lazygit, { desc = "Lazygit", silent = true })

-- NOTE: Preventing fetch of *all* origin branches/tags is primarily controlled by the repo's
-- git remote configuration, since Lazygit delegates to `git fetch`.
-- Useful per-repo settings:
--   git config remote.origin.tagOpt --no-tags
--   git config remote.origin.fetch "+refs/heads/main:refs/remotes/origin/main"
-- map("n", "s", "<nop>", { desc = "Disable default `s` keybind" })
-- Select more lines in visual mode - e.g. VV for 2 lines, VVV for 3 lines
map("x", "V", "j")

-- Testing
map("n", "<Leader>tr", "<cmd>:TestNearest<cr>", { desc = "Run test" })
map("n", "<leader>td", "<cmd>:%s/\\<it\\.only\\>/it/g<cr>``", { desc = "Delete `it.only` in file" })
map("n", "<leader>ti", toggle_it_only, { desc = "Toggle `it.only` on line", noremap = true, silent = true })

-- Clear highlight of search, messages, floating windows
--
-- IMPORTANT UX NOTE:
-- We intentionally do NOT close floating windows on insert-mode <Esc>, because that
-- makes exiting insert mode disruptive (e.g. it would close Snacks explorer).
local function close_focusable_floats()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local cfg = vim.api.nvim_win_get_config(win)
		local is_float = cfg.relative ~= nil and cfg.relative ~= ""
		local is_focusable = cfg.focusable == true
		if is_float and is_focusable then
			pcall(vim.api.nvim_win_close, win, false)
		end
	end
end

-- Normal mode: clear hl + close focusable floating windows + hide notifier
map("n", "<Esc>", function()
	vim.cmd([[nohl]])
	close_focusable_floats()
	require("snacks.notifier").hide()
end, { desc = "Clear highlight, floating windows" })

-- Insert mode: exit insert + clear hl + hide notifier (but do NOT close floats)
map("i", "<Esc>", function()
	vim.cmd([[stopinsert]])
	vim.cmd([[nohl]])
	require("snacks.notifier").hide()
end, { desc = "Exit insert + clear highlight" })

-- Invoke VIM command to move j/k directions + keep cursor centered for any buffers with line numbers
-- This method means all plugin buffers will be excluded and use standard vim behaviour
local keep_cursor_centered = function(jk_direction)
	local excluded_filetypes = { "harpoon", "minifiles" }

	-- Invoke norm command if filetype is in excluded list
	for _, filetype in ipairs(excluded_filetypes) do
		if vim.o.filetype == filetype then
			vim.cmd("norm! " .. jk_direction)
			return
		end
	end

	vim.cmd("norm! " .. jk_direction .. "zz") -- Keep cursor centered on all vertical movements
end

-- Keep cursor centered when navigating
map("n", "k", function()
	keep_cursor_centered("k")
end, { desc = "Keep cursor centered on up" })
map("n", "j", function()
	keep_cursor_centered("j")
end, { desc = "Keep cursor centered on down" })
map("n", "G", "Gzz", { desc = "Keep cursor centered on page end" })
map("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor centered on page up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor centered on page down" })
map("n", "*", "*zz", { desc = "Keep cursor centered on search next" })
map("n", "#", "#zz", { desc = "Keep cursor centered on search previous" })

-- Delete entire line without yanking it into the default register
map("n", "dd", '"_dd', { desc = "Delete line without yank" })

-- HJKL insert mode navigation
-- map("i", "<C-h>", move_left, { desc = "Move cursor left" })
-- map("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
-- map("i", "<C-k>", "<Up>", { desc = "Move cursor up" })
-- map("i", "<C-l>", move_right, { desc = "Move cursor right" })

-- LSP keymaps
map("n", "gr", telescope_builtin.lsp_references, { desc = "Find all references" })
map("n", "gR", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[n]ame" })
map("n", "gA", LazyVim.lsp.action.source, { desc = "Source Action" })
map("n", "gh", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "go", LazyVim.lsp.action["source.organizeImports"], { desc = "Format" })
map({ "n", "v" }, "==", function()
	LazyVim.format({ force = true })
end, { desc = "Format" })
map({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "[C]ode [F]ormat" })

-- Before/After
map("n", "[o", "m`O<esc>d0x``", { desc = "Empty line above" }) -- new line before
map("n", "]o", "m`o<esc>d0x``", { desc = "Empty line below" }) -- new line after
map("n", "<Leader>O", "m`O<esc>d0x``", { desc = "Empty line above" }) -- new line before
map("n", "<Leader>o", "m`o<esc>d0x``", { desc = "Empty line below" }) -- new line after
map("n", "[p", "m`P``", { desc = "Paste before" }) -- paste before

-- No yank on visual paste
map("v", "p", "P", { noremap = true, silent = true })

-- Mouse selection copies to clipboard
map("v", "<LeftRelease>", '"*ygv', { desc = "Mouse selection copies to clipboard" })

map("n", "<leader>ug", "<cmd>:lua require('tint').toggle()<cr>", { desc = "Toggle tint" })

local copy_file_path = function(path)
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path)
end

local copy_file_path_with_lines = function(path)
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")

	-- Ensure start_line is always the smaller number
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	local path_with_lines
	if start_line == end_line then
		path_with_lines = path .. ":" .. start_line
	else
		path_with_lines = path .. ":" .. start_line .. "-" .. end_line
	end

	vim.fn.setreg("+", path_with_lines)
	vim.notify("Copied: " .. path_with_lines)
end

map({ "n", "v" }, "<Leader>yp", function()
	copy_file_path(vim.fn.expand("%"))
end, { desc = "Copy relative file path" })

map({ "n", "v" }, "<Leader>yP", function()
	copy_file_path(vim.fn.expand("%:p"))
end, { desc = "Copy absolute file path" })

map({ "n", "v" }, "<Leader>yl", function()
	local path = vim.fn.expand("%")
	if vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "\22" then
		copy_file_path_with_lines(path)
	else
		-- In normal mode, just use current line
		local current_line = vim.fn.line(".")
		local path_with_line = path .. ":" .. current_line
		vim.fn.setreg("+", path_with_line)
		vim.notify("Copied: " .. path_with_line)
	end
end, { desc = "Copy relative file path with line numbers" })

--- TMUX navigation
map("n", "<C-h>", "<cmd>lua require'smart-splits'.move_cursor_left()<cr>", { desc = "Go to left window" })
map("n", "<C-j>", "<cmd>lua require'smart-splits'.move_cursor_down()<cr>", { desc = "Go to lower window" })
map("n", "<C-k>", "<cmd>lua require'smart-splits'.move_cursor_up()<cr>", { desc = "Go to upper window" })
map("n", "<C-l>", "<cmd>lua require'smart-splits'.move_cursor_right()<cr>", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>lua require'smart-splits'.resize_up()<cr>", { desc = "Resize top" })
map("n", "<C-Down>", "<cmd>lua require'smart-splits'.resize_down()<cr>", { desc = "Resize bottom" })
map("n", "<C-Left>", "<cmd>lua require'smart-splits'.resize_left()<cr>", { desc = "Resize left" })
map("n", "<C-Right>", "<cmd>lua require'smart-splits'.resize_right()<cr>", { desc = "Resize right" })

return M
