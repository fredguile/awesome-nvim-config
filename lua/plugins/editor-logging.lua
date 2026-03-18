return {
	-- quick adding log statements
	{
		"chrisgrieser/nvim-chainsaw",
		event = "VeryLazy",
		cond = true,
		dependencies = { "folke/which-key.nvim" },
		config = function()
			if vim.g.vscode then
				return
			end
			local ok, wk = pcall(require, "which-key")
			if ok then
				wk.add({ "<leader>l", group = "+logging" })
			end
		end,
		opts = {
			marker = "🖨️",
			logStatements = {
				objectLog = {
					typescript = "console.log('{{marker}} {{var}}:', JSON.stringify({{var}}, null, 2));",
				},
			},
		},
		cmd = "ChainSaw",
		keys = {
      -- stylua: ignore start
      { "<leader>ll", function() require("chainsaw").variableLog() end, mode = { "n", "x" }, desc = "󰐪 variable" },
      { "<leader>lo", function() require("chainsaw").objectLog() end, mode = { "n", "x" }, desc = "󰐪 object" },
      -- { "<leader>la", function() require("chainsaw").assertLog() end, mode = { "n", "x" }, desc = "󰐪 assert" },
      -- { "<leader>lt", function() require("chainsaw").typeLog() end, mode = { "n", "x" }, desc = "󰐪 type" },
      { "<leader>lm", function() require("chainsaw").messageLog() end, desc = "󰐪 message" },
      -- { "<leader>lb", function() require("chainsaw").beepLog() end, desc = "󰐪 beep" },
      { "<leader>l1", function() require("chainsaw").timeLog() end, desc = "󰐪 time" },
      { "<leader>ld", function() require("chainsaw").debugLog() end, desc = "󰐪 debugger" },
      { "<leader>ls", function() require("chainsaw").stacktraceLog() end, desc = "󰐪 stacktrace" },
      -- { "<leader>lk", function() require("chainsaw").clearLog() end, desc = "󰐪 clear" },
      { "<leader>lr", function() require("chainsaw").removeLogs() end, desc = "󰐪 󰅗 remove logs" },
		},
	},
}
