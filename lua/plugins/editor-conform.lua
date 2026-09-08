-- ---------------------------------------------------------------------------
-- Spotless detection
-- ---------------------------------------------------------------------------
-- Skip google-java-format (and the LSP fallback) when the project uses
-- Spotless. Spotless can apply a different formatter (palantir-java-format,
-- eclipse, google-java-format with custom rules) plus import ordering,
-- unused-import removal, and annotation formatting — none of which match a
-- bare google-java-format run, so every save would churn against the next
-- `spotless:apply`.
--
-- Strategy:
--   1. Walk up from the buffer's directory, checking every pom.xml /
--      build.gradle[.kts] / settings.gradle[.kts]. In multi-module Maven
--      builds, Spotless is usually declared in the root pom.xml and inherits
--      down to sub-modules via Maven plugin inheritance — so a file deep in
--      `scanner-app/src/main/java` still needs to walk to the parent pom.xml.
--   2. On detection, set `vim.b.autoformat = false` so LazyVim's LazyFormat
--      (which is what drives format-on-save here, not conform's own
--      `format_on_save` — LazyVim strips that from conform's opts) skips
--      formatting entirely, including the LSP fallback that would otherwise
--      trigger jdtls's built-in formatter.
--   3. Also guard the manual `<leader>f` keybind against the same fallback.

local function read_file(path)
	local fd, _ = io.open(path, "r")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	return content
end

local function maven_has_spotless(path)
	local content = read_file(path)
	if not content then
		return false
	end
	return content:find("spotless-maven-plugin", 1, true) ~= nil
end

local function gradle_has_spotless(path)
	local content = read_file(path)
	if not content then
		return false
	end
	-- Spotless can be wired in a few ways:
	--   apply plugin: 'spotless'
	--   id("spotless")
	--   id("com.diffplug.spotless")
	--   plugins { id "spotless" }
	--   classpath("com.diffplug.spotless:...")
	local patterns = {
		"apply%s+plugin%s*:%s*['\"]spotless['\"]",
		"apply%s+plugin%s*:%s*['\"]com%.diffplug%.spotless['\"]",
		'id%s*%(%s*[\'"]spotless[\'"]%s*%)',
		'id%s*%(%s*[\'"]com%.diffplug%.spotless[\'"]%s*%)',
		"com%.diffplug%.spotless",
	}
	for _, pat in ipairs(patterns) do
		if content:find(pat) then
			return true
		end
	end
	return false
end

local function check_any_spotless_at(dir)
	local pom = dir .. "/pom.xml"
	if vim.fn.filereadable(pom) == 1 and maven_has_spotless(pom) then
		return true
	end
	for _, name in ipairs({ "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" }) do
		local p = dir .. "/" .. name
		if vim.fn.filereadable(p) == 1 and gradle_has_spotless(p) then
			return true
		end
	end
	return false
end

local spotless_cache = {}

local function detect_spotless(start)
	if not start or start == "" then
		return false
	end
	if spotless_cache[start] ~= nil then
		return spotless_cache[start]
	end

	local dir = vim.fn.fnamemodify(start, ":p")
	if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
		dir = dir:sub(1, -2)
	end

	local result = false
	while dir and dir ~= "" do
		if check_any_spotless_at(dir) then
			result = true
			break
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir or parent == "" then
			break
		end
		dir = parent
	end

	spotless_cache[start] = result
	return result
end

local function buf_has_spotless(bufnr)
	if vim.bo[bufnr].filetype ~= "java" then
		return false
	end
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return false
	end
	local dir = vim.fn.fnamemodify(path, ":p:h")
	return detect_spotless(dir)
end

-- Per-buffer "we skipped format-on-save" notification. Register a BufDelete
-- hook so the cache entry clears when the buffer goes away.
local notified_buffers = {}

local function notify_spotless_skip(bufnr)
	if notified_buffers[bufnr] then
		return
	end
	notified_buffers[bufnr] = true
	vim.api.nvim_create_autocmd("BufDelete", {
		buffer = bufnr,
		once = true,
		callback = function()
			notified_buffers[bufnr] = nil
		end,
	})
	vim.notify(
		"Spotless detected — Java format-on-save skipped. Use <leader>js to run spotless:apply.",
		vim.log.levels.INFO
	)
end

local function disable_format_for_buf(bufnr)
	if vim.b[bufnr].autoformat ~= false then
		vim.b[bufnr].autoformat = false
	end
end

local function setup_spotless_autocmds()
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("spotless-detect", { clear = true }),
		callback = function(args)
			if buf_has_spotless(args.buf) then
				disable_format_for_buf(args.buf)
				notify_spotless_skip(args.buf)
			end
		end,
	})
end

-- ---------------------------------------------------------------------------
-- Manual format handler: skip when Spotless is in use, otherwise defer to
-- conform. We can't rely solely on `vim.b.autoformat` here because the user
-- is invoking format explicitly.
-- ---------------------------------------------------------------------------
local function manual_format()
	local bufnr = vim.api.nvim_get_current_buf()
	if buf_has_spotless(bufnr) then
		notify_spotless_skip(bufnr)
		return
	end
	require("conform").format({ async = true, lsp_fallback = true })
end

-- ---------------------------------------------------------------------------
-- Spotless runner (Maven + Gradle) for the <leader>js keybind
-- ---------------------------------------------------------------------------

local function resolve_maven()
	if vim.fn.filereadable(vim.fn.getcwd() .. "/mvnw") == 1 then
		return vim.fn.getcwd() .. "/mvnw"
	end
	if vim.fn.executable("mise") == 1 then
		local out = vim.fn.systemlist({ "mise", "which", "mvn" })
		if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
			return out[1]
		end
	end
	local global = vim.fn.exepath("mvn")
	if global ~= "" then
		return global
	end
	return "mvn"
end

local function resolve_gradle()
	if vim.fn.filereadable(vim.fn.getcwd() .. "/gradlew") == 1 then
		return vim.fn.getcwd() .. "/gradlew"
	end
	local global = vim.fn.exepath("gradle")
	if global ~= "" then
		return global
	end
	return "gradle"
end

local function run_spotless()
	local cwd = vim.fn.getcwd()
	if vim.fn.findfile("pom.xml", cwd) ~= "" then
		vim.cmd("!" .. resolve_maven() .. " spotless:apply")
	else
		vim.cmd("!" .. resolve_gradle() .. " spotlessApply")
	end
end

return {
	"stevearc/conform.nvim",
	-- BufReadPost makes the plugin load early so init() can register the
	-- Spotless-detection autocmd before any Java buffer is opened.
	event = { "BufReadPost", "BufWritePre" },
	cmd = { "ConformInfo" },
	init = function()
		setup_spotless_autocmds()
		-- Handle the buffer that triggered this load (init runs at plugin
		-- load time, after BufReadPost fires for the current buffer).
		local cur = vim.api.nvim_get_current_buf()
		if buf_has_spotless(cur) then
			disable_format_for_buf(cur)
			notify_spotless_skip(cur)
		end
	end,
	keys = {
		{
			"<leader>f",
			function()
				manual_format()
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
		{
			"<leader>js",
			function()
				run_spotless()
			end,
			desc = "[J]ava [S]potless apply",
			silent = true,
		},
	},
	opts = {
		formatters_by_ft = {
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			tsx = { "prettier" },
			jsx = { "prettier" },
			graphql = { "prettier" },
			gql = { "prettier" },
			css = { "prettier" },
			html = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			python = { "ruff_format" },
			lua = { "stylua" },
			java = { "google-java-format" },
		},
	},
}