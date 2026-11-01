-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Re-apply the per buffer wrap preference (b:wrap_fit, set by `<leader>ww`) in
-- new windows, so splitting a buffer keeps the toggled state.
require("util.wrap").setup()
