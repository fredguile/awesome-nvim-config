return {
  {
    "mvllow/modes.nvim",
    event = "VeryLazy",
    config = function()
      require("modes").setup({
        set_cursor = true,
        set_cursorline = true,
        set_number = true,
      })

      -- Make the mode change extra obvious: enable cursorline only in Insert mode
      local group = vim.api.nvim_create_augroup("RovoDevModesCursorline", { clear = true })
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        callback = function()
          vim.wo.cursorline = true
        end,
      })
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
          vim.wo.cursorline = false
        end,
      })
    end,
  },
}
