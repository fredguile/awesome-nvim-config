-- https://github.com/eatgrass/maven.nvim
return {
	"eatgrass/maven.nvim",
	cmd = { "Maven", "MavenExec" },
	dependencies = "nvim-lua/plenary.nvim",
	lazy = true,
	keys = {
		{
			"<leader>m",
			":Maven<CR>",
			desc = "Maven Commands",
			silent = true,
		},
	},
	config = function()
		local function resolve_maven_executable()
			local local_wrapper = vim.fn.getcwd() .. "/mvnw"
			if vim.fn.filereadable(local_wrapper) == 1 then
				return local_wrapper
			end

			if vim.fn.executable("mise") == 1 then
				local output = vim.fn.systemlist({ "mise", "which", "mvn" })
				if vim.v.shell_error == 0 and output and output[1] and output[1] ~= "" then
					return output[1]
				end
			end

			local global_maven = vim.fn.exepath("mvn")
			if global_maven ~= "" then
				return global_maven
			end

			return "mvn"
		end

		local maven_module = require("maven")

		-- Override execute_command to filter out nil values from output
		local original_execute_command = maven_module.execute_command
		function maven_module.execute_command(command)
			if command == nil then
				vim.notify("No maven command")
				return
			end

			local config = require("maven.config")
			local cwd = config.options.cwd or vim.fn.getcwd()

			if vim.fn.findfile("pom.xml", cwd) == "" then
				vim.notify("no pom.xml file found under " .. cwd, vim.log.levels.ERROR)
				return
			end

			maven_module.kill_running_job()

			local View = require("maven.view")
			local args = {}

			if config.options.settings ~= nil and config.options.settings ~= "" then
				table.insert(args, "-s")
				table.insert(args, config.options.settings)
			end

			for _, arg in pairs(command.cmd) do
				table.insert(args, arg)
			end

			local view = View.create()

			local job = require("plenary.job"):new({
				command = config.options.executable,
				args = args,
				cwd = cwd,
				on_stdout = function(_, data)
					-- Filter out nil values that appear at the end of output
					if data then
						view:render_line(data)
					end
				end,
				on_stderr = function(_, data)
					-- Filter out nil values that appear at the end of output
					if data then
						vim.schedule(function()
							view:render_line(data)
						end)
					end
				end,
			})

			view.job = job
			job:start()
		end

		maven_module.setup({
			executable = resolve_maven_executable(),
			cwd = nil,
			settings = nil,
			commands = { -- add custom goals to the command list
				{ cmd = { "clean", "install", "-DskipTests" }, desc = "install (skip tests)" },
				{ cmd = { "spotless:apply" }, desc = "apply Spotless formatting" },
			},
		})
	end,
}
