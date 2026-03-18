-- https://github.com/nvim-java/nvim-java

local uv = vim.loop

local function trim(str)
	if type(str) ~= "string" then
		return nil
	end
	local trimmed = str:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil
	end
	return trimmed
end

local function resolve_java21_home()
	local sysname = ""
	if uv and uv.os_uname then
		sysname = (uv.os_uname().sysname or ""):lower()
	end

	if sysname == "darwin" then
		local output = vim.fn.system({ "/usr/libexec/java_home", "-v", "21" })
		if vim.v.shell_error == 0 then
			local home = trim(output)
			if home then
				return home
			end
		end
	else
		local fs_realpath = uv and uv.fs_realpath or nil
		local fs_stat = uv and uv.fs_stat or nil
		local candidates = {
			"/usr/lib/jvm/java-21-openjdk-amd64",
			"/usr/lib/jvm/java-21-openjdk",
			"/usr/lib/jvm/java-21-openjdk-arm64",
			"/usr/lib/jvm/java-21-openjdk-x86_64",
			"/usr/lib/jvm/default-java",
		}

		for _, candidate in ipairs(candidates) do
			local resolved = fs_realpath and fs_realpath(candidate) or nil
			if resolved and resolved ~= "" then
				return resolved
			end
			if fs_stat and fs_stat(candidate) then
				return candidate
			end
		end
	end

	return vim.env.JAVA_HOME or "/opt/jdk-21"
end

local function has_jdtls()
	local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
	local ok, clients = pcall(get_clients, { name = "jdtls" })
	if not ok then
		clients = get_clients()
	end
	if not clients then
		return false
	end
	for _, client in ipairs(clients) do
		if client.name == "jdtls" then
			return true
		end
	end
	return false
end

local function with_jdtls(command)
	return function()
		if not has_jdtls() then
			vim.notify("JDTLS is not running; open a Java project first", vim.log.levels.WARN)
			return
		end
		vim.cmd(command)
	end
end

return {
	"nvim-java/nvim-java",
	lazy = false,
	keys = {
		{
			"<leader>jb",
			with_jdtls("JavaBuildBuildWorkspace"),
			desc = "Java: Build workspace",
			silent = true,
		},
		{
			"<leader>jr",
			with_jdtls("JavaRunnerRunMain"),
			desc = "Java: Run main class",
			silent = true,
		},
		{
			"<leader>jt",
			with_jdtls("JavaTestRunCurrentClass"),
			desc = "Java: Test current class",
			silent = true,
		},
		{
			"<leader>jo",
			with_jdtls("JavaTestRunCurrentClass"),
			desc = "Java: Open last test report",
			silent = true,
		},
	},
	config = function()
		require("java").setup()

		vim.lsp.config("jdtls", {
			settings = {
				java = {
					configuration = {
						runtimes = {
							{
								name = "JavaSE-21",
								path = resolve_java21_home(),
								default = true,
							},
						},
					},
				},
			},
		})

		vim.lsp.enable("jdtls")
	end,
}
