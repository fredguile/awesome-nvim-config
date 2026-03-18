return {
	"stevearc/oil.nvim",
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	opts = {},
	keys = {
		{
			"\\\\",
			function()
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					vim.notify("Oil is disabled while connected via SSHFS", vim.log.levels.WARN)
					return
				end
				vim.cmd("Oil")
			end,
			desc = "Oil reveal (disabled when remote)",
			silent = true,
		},
	},
	config = function(_, opts)
		require("oil").setup(opts)

		-- Guard :Oil while remote-sshfs is connected.
		-- This keeps manual :Oil invocations from trying to browse the SSHFS mount.
		pcall(vim.api.nvim_del_user_command, "Oil")
		vim.api.nvim_create_user_command("Oil", function(cmd)
			local ok_conn, connections = pcall(require, "remote-sshfs.connections")
			if ok_conn and connections.is_connected() then
				vim.notify("Oil is disabled while connected via SSHFS", vim.log.levels.WARN)
				return
			end
			local ok_oil, oil = pcall(require, "oil")
			if not ok_oil then
				return
			end
			-- If a directory was provided (e.g. :Oil . or :Oil /path), pass it through.
			local arg = cmd.args
			if arg == "" then
				pcall(oil.open)
			else
				pcall(oil.open, arg)
			end
		end, { nargs = "?", complete = "dir" })
	end,

	-- Optional dependencies
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
}
