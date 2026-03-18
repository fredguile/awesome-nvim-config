return {
	"nosduco/remote-sshfs.nvim",
	enabled = false,
	dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	keys = {
		{
			"<leader>rc",
			function()
				require("remote-sshfs.api").connect()
			end,
			desc = "Remote: Connect (SSHFS)",
		},
		{
			"<leader>rd",
			function()
				require("remote-sshfs.api").disconnect()
			end,
			desc = "Remote: Disconnect (SSHFS)",
		},
		{
			"<leader>re",
			function()
				require("remote-sshfs.api").edit()
			end,
			desc = "Remote: Edit SSH config",
		},
		{
			"<leader>rf",
			function()
				require("remote-sshfs.api").find_files()
			end,
			desc = "Remote: Find files",
		},
		{
			"<leader>rg",
			function()
				require("remote-sshfs.api").live_grep()
			end,
			desc = "Remote: Live grep",
		},

		-- Override common LazyVim search mappings to be remote-aware
		{
			"<leader>sf",
			function()
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					require("remote-sshfs.api").find_files()
					return
				end

				local ok_builtin, builtin = pcall(require, "telescope.builtin")
				if ok_builtin then
					builtin.find_files()
				else
					vim.cmd("Telescope find_files")
				end
			end,
			desc = "Find files (remote-aware)",
		},
		{
			"<leader>sg",
			function()
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					require("remote-sshfs.api").live_grep()
					return
				end

				local ok_builtin, builtin = pcall(require, "telescope.builtin")
				if ok_builtin then
					builtin.live_grep()
				else
					vim.cmd("Telescope live_grep")
				end
			end,
			desc = "Grep (remote-aware)",
		},
		{
			"<leader>sG",
			function()
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					require("remote-sshfs.api").live_grep()
					return
				end

				local ok_builtin, builtin = pcall(require, "telescope.builtin")
				if ok_builtin then
					builtin.live_grep()
				else
					vim.cmd("Telescope live_grep")
				end
			end,
			desc = "Grep (remote-aware)",
		},
		{
			"<leader>sw",
			function()
				local word = vim.fn.expand("<cword>")
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					-- Use remote live_grep pre-filled with the word under cursor
					local ok_telescope, telescope = pcall(require, "telescope")
					if ok_telescope then
						telescope.extensions["remote-sshfs"].live_grep({ default_text = word })
					else
						require("remote-sshfs.api").live_grep()
					end
					return
				end

				local ok_builtin, builtin = pcall(require, "telescope.builtin")
				if ok_builtin then
					builtin.grep_string({ search = word })
				else
					vim.cmd("Telescope grep_string")
				end
			end,
			desc = "Grep word (remote-aware)",
		},
		{
			"<leader>sW",
			function()
				local word = vim.fn.expand("<cWORD>")
				local ok_conn, connections = pcall(require, "remote-sshfs.connections")
				if ok_conn and connections.is_connected() then
					local ok_telescope, telescope = pcall(require, "telescope")
					if ok_telescope then
						telescope.extensions["remote-sshfs"].live_grep({ default_text = word })
					else
						require("remote-sshfs.api").live_grep()
					end
					return
				end

				local ok_builtin, builtin = pcall(require, "telescope.builtin")
				if ok_builtin then
					builtin.grep_string({ search = word })
				else
					vim.cmd("Telescope grep_string")
				end
			end,
			desc = "Grep WORD (remote-aware)",
		},
	},
	opts = {
		connections = {
			ssh_configs = {
				vim.fn.expand("$HOME") .. "/.ssh/config",
				"/etc/ssh/ssh_config",
			},
			ssh_known_hosts = vim.fn.expand("$HOME") .. "/.ssh/known_hosts",
			sshfs_args = {
				"-o reconnect",
				"-o ConnectTimeout=5",
			},
		},
		mounts = {
			base_dir = vim.fn.expand("$HOME") .. "/.sshfs/",
			unmount_on_exit = false,
		},
		handlers = {
			on_connect = {
				change_dir = true,
			},
			on_disconnect = {
				clean_mount_folders = false,
			},
			on_edit = {},
		},
		ui = {
			select_prompts = false,
			confirm = {
				connect = false,
				change_dir = false,
			},
		},
		log = {
			enabled = true,
			-- Keep full output so sshfs errors aren't lost
			truncate = true,
			types = {
				-- Targeted logging (enable more if needed)
				all = false,
				util = false,
				handler = true,
				sshfs = true,
			},
		},
	},
	config = function(_, opts)
		local ok, remote_sshfs = pcall(require, "remote-sshfs")
		if not ok then
			return
		end

		remote_sshfs.setup(opts)

		-- Workaround for remote-sshfs.nvim failing to parse fingerprints when ssh-keyscan
		-- returns banner/comment lines first (e.g. "# host:22 SSH-2.0-..."), which can
		-- break `ssh-keygen -lf` on that first line.
		--
		-- Since you selected auto-adding keys (no prompt), we pre-seed the configured
		-- known_hosts entry with a filtered ssh-keyscan result before mounting.
		do
			local ok_conn, connections = pcall(require, "remote-sshfs.connections")
			if ok_conn and not connections.__known_hosts_autoseed_patched then
				connections.__known_hosts_autoseed_patched = true

				local original_mount_host = connections.mount_host
				connections.mount_host = function(host, mount_dir, ask_pass)
					local known_hosts = opts.connections and opts.connections.ssh_known_hosts
					if type(known_hosts) == "string" and known_hosts ~= "" then
						local hostname = host["HostName"] or host["Name"]
						local lookup_host = hostname
						if host["Port"] and host["Port"] ~= "22" then
							lookup_host = "[" .. hostname .. "]:" .. host["Port"]
						end

						local known_info = vim.fn.system({ "ssh-keygen", "-F", lookup_host, "-f", known_hosts })
						if not (type(known_info) == "string" and known_info:find("found")) then
							local scan_cmd = { "ssh-keyscan", "-T", "5" }
							if host["Port"] then
								table.insert(scan_cmd, "-p")
								table.insert(scan_cmd, host["Port"])
							end
							table.insert(scan_cmd, hostname)

							local scan_result = vim.fn.system(scan_cmd)
							if vim.v.shell_error == 0 and type(scan_result) == "string" and scan_result ~= "" then
								local lines = vim.split(scan_result, "\n", { plain = true, trimempty = true })
								local filtered = {}
								for _, line in ipairs(lines) do
									-- Drop banner/comment lines and any garbage
									if line ~= "" and not vim.startswith(line, "#") then
										table.insert(filtered, line)
									end
								end

								if #filtered > 0 then
									local fh = io.open(known_hosts, "a")
									if fh then
										fh:write(table.concat(filtered, "\n"))
										fh:write("\n")
										fh:close()
										vim.notify(
											"[remote-sshfs] Auto-added host key(s) for "
												.. hostname
												.. " to "
												.. known_hosts
										)
									end
								end
							end
						end
					end

					return original_mount_host(host, mount_dir, ask_pass)
				end
			end
		end

		local ok_telescope, telescope = pcall(require, "telescope")
		if ok_telescope then
			telescope.load_extension("remote-sshfs")
		end

		local ok_wk, wk = pcall(require, "which-key")
		if ok_wk then
			wk.add({ "<leader>r", group = "+remote" })
		end

		require("remote-sshfs").callback.on_connect_success:add(function(host, mount_dir)
			local host_name = host
			if type(host) == "table" then
				host_name = host.Name or host.HostName or host.Host or "<unknown-host>"
			end
			vim.notify("Mounted " .. tostring(host_name) .. " at " .. mount_dir)

			-- Oil + SSHFS: Oil can behave unexpectedly on fresh FUSE mounts.
			-- If Oil is open, close its buffers when connecting to a remote.
			vim.schedule(function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "oil" then
						pcall(vim.api.nvim_buf_delete, buf, { force = true })
					end
				end
			end)
		end)
	end,
}
