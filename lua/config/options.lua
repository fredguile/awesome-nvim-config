-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Manually set Node path for lazy.nvim
-- vim.g.node_host_prog = '~/.nvm/versions/node/v20.10.0/lib/node_modules'
-- vim.g.copilot_node_command = '~/.nvm/versions/node/v20.10.0/bin/node'

local opt = vim.opt
opt.clipboard = "unnamedplus"

if vim.fn.has("wsl") == 1 and vim.fn.executable("win32yank.exe") == 1 then
	vim.g.clipboard = "win32yank"
elseif vim.env.SSH_CONNECTION then
	vim.g.clipboard = {
		name = "OSC 52 (copy only)",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			["+"] = function()
				return {}
			end,
			["*"] = function()
				return {}
			end,
		},
	}
end

-- Configure tab to use space characters, never tab characters
opt.expandtab = true

-- Set listchars
opt.list = true
opt.listchars:append("space:⋅")
opt.listchars:append("tab:» ")
opt.listchars:append("trail:~")

-- Turn on spell checking
opt.spell = false
opt.spelllang = "en_us"

-- Recommended setting by avante.nvim for views
-- @see https://github.com/yetone/avante.nvim
opt.laststatus = 3

-- Highlight current line
-- Only enable in Insert mode (see lua/plugins/editor-modes.lua)
opt.cursorline = false

-- Performance optimizations for large monorepos
-- Limit shada file size to improve quit performance
opt.shada = "!,'50,<50,s10,h" -- Reduced from default '100 to '50 marks

-- Reduce sessionoptions to speed up session saving (if sessions are used)
opt.sessionoptions = { "curdir", "tabpages", "winsize" } -- Removed buffers/globals/folds for speed

-- UX: when leaving a CodeCompanion buffer and focusing a real file buffer,
-- automatically exit Insert mode so normal-mode keymaps work as expected.
vim.g.codecompanion_stopinsert_on_file_enter = true
