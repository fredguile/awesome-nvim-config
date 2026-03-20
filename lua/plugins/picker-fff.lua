return {
	"dmtrKovalenko/fff.nvim",

	-- Track latest fff.nvim.
	-- Native backend is built locally using stable Rust.
	build = function()
	  require("fff.download").download_or_build_binary()
	end,

	-- No need to lazy-load with lazy.nvim.
	-- This plugin initializes itself lazily.
	lazy = false,

	-- Ensure the native backend is not stale.
	-- Symptom of staleness: `require('fff.fuzzy').live_grep` ends up nil at runtime.
	init = function()
		-- Patch fff.nvim startup init to avoid crashes when native errors are returned as userdata.
		-- Upstream `fff.core` concatenates `result` directly in notifications, which can error if `result` is userdata.
		do
			local ok_core, core = pcall(require, "fff.core")
			if ok_core and type(core.ensure_initialized) == "function" then
				local orig_ensure = core.ensure_initialized
				core.ensure_initialized = function(...)
					local ok, res = pcall(orig_ensure, ...)
					if ok then
						return res
					end
					vim.schedule(function()
						vim.notify("FFF: initialization failed: " .. tostring(res), vim.log.levels.ERROR)
					end)
					-- Return fuzzy module if available to keep callers from exploding
					local ok_fuzzy, fuzzy = pcall(require, "fff.fuzzy")
					if ok_fuzzy then
						return fuzzy
					end
				end
			end
		end

		-- Guard: if backend is missing grep symbols, don't crash fff's grep picker.
		-- Instead, attempt to download the correct backend and tell the user to restart.
		local function wrap_live_grep()
			local ok_fff, fff = pcall(require, "fff")
			if not ok_fff or type(fff.live_grep) ~= "function" then
				return
			end
			local orig = fff.live_grep
			fff.live_grep = function(opts)
				local ok_rust, rust = pcall(require, "fff.rust")
				if ok_rust and type(rust.live_grep) == "function" then
					return orig(opts)
				end

				local function build_backend(reason)
					local plugin_dir = vim.fn.stdpath("data") .. "/lazy/fff.nvim"
					vim.notify(
						"fff.nvim: rebuilding native backend" .. (reason and (" (" .. reason .. ")") or ""),
						vim.log.levels.WARN
					)
					vim.system({ "cargo", "build", "--release" }, { cwd = plugin_dir }, function(res)
						vim.schedule(function()
							if res.code == 0 then
								vim.notify("fff.nvim: native backend rebuilt. Please restart Neovim, then run grep again.", vim.log.levels.INFO)
							else
								vim.notify(
									"fff.nvim: failed to rebuild native backend: " .. (res.stderr ~= "" and res.stderr or tostring(res.code)),
									vim.log.levels.ERROR
								)
							end
						end)
					end)
				end

				build_backend("grep support missing")
			end
		end

		wrap_live_grep()

		-- Background check: if the backend binary is missing/stale, rebuild it.
		vim.schedule(function()
			local plugin_dir = vim.fn.stdpath("data") .. "/lazy/fff.nvim"
			local grep_lua = plugin_dir .. "/lua/fff/grep/init.lua"

			local function stat(path)
				return (vim.uv or vim.loop).fs_stat(path)
			end

			-- The rust loader looks for: target/release/libfff_nvim.{so|dylib|dll}
			local ext = (jit.os:lower() == "mac" or jit.os:lower() == "osx") and "dylib"
				or (jit.os:lower() == "windows" and "dll" or "so")
			local bin = plugin_dir .. "/target/release/libfff_nvim." .. ext

			local grep_stat = stat(grep_lua)
			local bin_stat = stat(bin)

			local stale = false
			if grep_stat and (not bin_stat) then
				stale = true
			elseif grep_stat and bin_stat and bin_stat.mtime.sec < grep_stat.mtime.sec then
				stale = true
			end

			local ok_rust, rust = pcall(require, "fff.rust")
			local missing_symbols = ok_rust and type(rust.live_grep) ~= "function"

			if stale or missing_symbols then
				vim.notify("fff.nvim: rebuilding native backend in background…", vim.log.levels.WARN)
				vim.system({ "cargo", "build", "--release" }, { cwd = plugin_dir }, function(res)
					vim.schedule(function()
						if res.code == 0 then
							vim.notify("fff.nvim: native backend rebuilt. Restart Neovim to load it.", vim.log.levels.INFO)
						else
							vim.notify(
								"fff.nvim: backend rebuild failed: " .. (res.stderr ~= "" and res.stderr or tostring(res.code)),
								vim.log.levels.ERROR
							)
						end
					end)
				end)
			end
		end)
	end,

	opts = {
		-- Keep auto-indexing on startup (plugin/fff.lua will call ensure_initialized when lazy_sync is false/nil)
		lazy_sync = false,
		debug = {
			enabled = false,
			show_scores = true,
		},
	},

	keys = {
		{
			"ff",
			function()
				local fff = require("fff")
				local cwd = vim.fn.expand("%:p:h")
				if type(fff.find_files) == "function" then
					fff.find_files({ cwd = cwd })
				else
					vim.notify("fff.find_files() not available; falling back to git root", vim.log.levels.WARN)
					fff.find_in_git_root()
				end
			end,
			desc = "Find files",
		},
	},
}
