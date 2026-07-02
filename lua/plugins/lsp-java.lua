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
-- nvim-java bundles its own jdtls downloader. The hardcoded jdtls version in
-- nvim-java may become unavailable on Eclipse's servers over time. Rather than
-- patching plugin files on disk (which makes lazy.nvim complain about dirty git
-- state), we monkey-patch the Lua module cache at runtime before nvim-java
-- reads it. Only JDTLS_VERSION and JDTLS_TIMESTAMP need updating when a newer
-- jdtls milestone is released at:
--   https://download.eclipse.org/jdtls/milestones/

local JDTLS_VERSION = "1.60.0"
local JDTLS_TIMESTAMP = "202606262232"
-- Java version range that this jdtls release supports
local JDTLS_JAVA_FROM = 21
local JDTLS_JAVA_TO = 25

--- Inject our jdtls version into the nvim-java Lua module cache so that:
---   1. pkgm.specs.jdtls-spec.version-map  knows the download timestamp
---   2. pkgm.specs (init.lua)              accepts the version (version_range)
---   3. java-core.constants.java_version   passes Java runtime validation
--- No files on disk are modified, so lazy.nvim never sees a dirty plugin repo.
local function patch_nvim_java_modules()
	-- 1. Extend the version-map with our timestamp
	local ok_vmap, vmap = pcall(require, "pkgm.specs.jdtls-spec.version-map")
	if ok_vmap and not vmap[JDTLS_VERSION] then
		vmap[JDTLS_VERSION] = JDTLS_TIMESTAMP
	end

	-- 2. Widen the version_range in the jdtls PackageSpec so is_match() accepts 1.60.0.
	--    specs/init.lua returns a plain table of Spec objects; we find the jdtls one
	--    and update its internal _version_range field.
	local ok_specs, specs = pcall(require, "pkgm.specs")
	if ok_specs then
		for _, spec in ipairs(specs) do
			if spec._name == "jdtls" and spec._version_range then
				if spec._version_range.to < JDTLS_VERSION then
					spec._version_range.to = JDTLS_VERSION
				end
			end
		end
	end

	-- 3. Extend the java_version constants table
	local ok_jver, jver = pcall(require, "java-core.constants.java_version")
	if ok_jver and not jver[JDTLS_VERSION] then
		jver[JDTLS_VERSION] = { from = JDTLS_JAVA_FROM, to = JDTLS_JAVA_TO }
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
		patch_nvim_java_modules()

		require("java").setup({
			jdtls = { version = JDTLS_VERSION },
		})

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
