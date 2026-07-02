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

-- https://github.com/nvim-java/nvim-java
--
-- nvim-java bundles its own jdtls downloader. When the hardcoded jdtls version
-- is no longer available on Eclipse's servers, the build hook below patches the
-- three internal files that need updating so Neovim continues to work after a
-- `lazy` plugin update. Update JDTLS_VERSION and JDTLS_TIMESTAMP when a newer
-- jdtls milestone is released at:
--   https://download.eclipse.org/jdtls/milestones/

local JDTLS_VERSION = "1.60.0"
local JDTLS_TIMESTAMP = "202606262232"
-- Java version range that this jdtls release supports (for validation)
local JDTLS_JAVA_FROM = 21
local JDTLS_JAVA_TO = 25

local function patch_nvim_java()
	local plugin_root = vim.fn.stdpath("data") .. "/lazy/nvim-java"

	-- 1. version-map.lua  (jdtls download URL timestamp)
	local vmap_path = plugin_root .. "/lua/pkgm/specs/jdtls-spec/version-map.lua"
	local vmap = io.open(vmap_path, "r")
	if vmap then
		local content = vmap:read("*a")
		vmap:close()
		if not content:find(JDTLS_VERSION, 1, true) then
			local entry = string.format("\t['%s'] = '%s',\n}", JDTLS_VERSION, JDTLS_TIMESTAMP)
			content = content:gsub("}", entry, 1)
			local f = io.open(vmap_path, "w")
			if f then
				f:write(content)
				f:close()
			end
		end
	end

	-- 2. config.lua  (JDTLS_VERSION default + version map)
	local conf_path = plugin_root .. "/lua/java/config.lua"
	local conf = io.open(conf_path, "r")
	if conf then
		local content = conf:read("*a")
		conf:close()
		-- Update JDTLS_VERSION constant
		content = content:gsub("local JDTLS_VERSION = '[^']*'", "local JDTLS_VERSION = '" .. JDTLS_VERSION .. "'")
		-- Inject version map entry if missing
		if not content:find(JDTLS_VERSION, 1, true) then
			local entry = string.format(
				"\t['%s'] = {\n\t\tlombok = '1.18.42',\n\t\tjava_test = '0.43.2',\n\t\tjava_debug_adapter = '0.58.3',\n\t\tspring_boot_tools = '1.55.1',\n\t\tjdk = '%d',\n\t},\n}",
				JDTLS_VERSION,
				JDTLS_JAVA_FROM
			)
			content = content:gsub("}\n\nlocal V", entry .. "\n\nlocal V", 1)
		end
		local f = io.open(conf_path, "w")
		if f then
			f:write(content)
			f:close()
		end
	end

	-- 3. java_version.lua  (Java runtime version range for validation)
	local jver_path = plugin_root .. "/lua/java-core/constants/java_version.lua"
	local jver = io.open(jver_path, "r")
	if jver then
		local content = jver:read("*a")
		jver:close()
		if not content:find(JDTLS_VERSION, 1, true) then
			local entry = string.format(
				"\t['%s'] = { from = %d, to = %d },\n}",
				JDTLS_VERSION,
				JDTLS_JAVA_FROM,
				JDTLS_JAVA_TO
			)
			content = content:gsub("}", entry, 1)
			local f = io.open(jver_path, "w")
			if f then
				f:write(content)
				f:close()
			end
		end
	end
end

return {
	"nvim-java/nvim-java",
	lazy = false,
	build = patch_nvim_java,
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
