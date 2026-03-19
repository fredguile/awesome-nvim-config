return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ikatyang/tree-sitter-yaml",
		"ravitemer/codecompanion-history.nvim",
	},
	lazy = false,
	keys = {
		-- which-key group
		{ "<leader>a", group = "codecompanion" },
		{ "<leader>ac", ":CodeCompanionChat Toggle<CR>", desc = "CodeCompanion: Chat", silent = true },
		{ "<leader>aa", ":CodeCompanionActions<CR>", desc = "CodeCompanion: Actions", silent = true },
		{
			"<leader>ah",
			function()
				-- Guard against Telescope crashing when the history list is empty.
				-- Also prefer Snacks picker (configured below) when available.
				local dir = vim.fn.stdpath("data") .. "/codecompanion-history"
				local ok_mkdir = pcall(vim.fn.mkdir, dir, "p")
				if not ok_mkdir then
					-- If we can't create/read the dir, still try to open history.
				end

				local files = vim.fn.glob(dir .. "/*", false, true)
				if not files or #files == 0 then
					vim.notify("CodeCompanion: no history yet", vim.log.levels.INFO)
					return
				end

				local ok, err = pcall(vim.cmd, "CodeCompanionHistory")
				if not ok then
					vim.notify(("CodeCompanionHistory failed: %s"):format(err or "unknown error"), vim.log.levels.ERROR)
				end
			end,
			desc = "CodeCompanion: History",
			silent = true,
		},
	},
	config = function()
		-- Apply patches to fix nil value errors before CodeCompanion initializes
		local codecompanion_fix = require("config.codecompanion-fix")
		
		local log = require("codecompanion.utils.log")

		local function preferred_acp_adapter()
			-- Prefer the RovoDev ACP adapter when the CLI is available.
			-- Fall back to CodeCompanion's built-in OpenCode ACP adapter otherwise.
			return (vim.fn.executable("acli") == 1) and "rovodev" or "opencode"
		end

		local default_adapter = preferred_acp_adapter()
		local cc_opts = { log_level = "DEBUG" }

		-- Title-generation adapter/model overrides
		-- When using ACP (RovoDev), generate titles via a lightweight local Ollama model.
		-- This works around upstream limitations where title generation may fail with ACP adapters.
		local title_adapter = nil
		local title_model = nil
		if default_adapter == "rovodev" then
			-- Use a dedicated HTTP adapter for title generation.
			-- This avoids CodeCompanion's HTTP client calling `adapter.schema.model.default()` without `self`,
			-- which breaks the built-in Ollama adapter (its default is a function(self, opts)).
			title_adapter = "ollama_title"
			title_model = "alibayram/smollm3:latest"
		end

		-- Debug-only, one-time notification showing which adapter is selected.
		-- (Useful to confirm `acli` detection and fallback behaviour.)
		if not vim.g.__codecompanion_adapter_notified then
			vim.g.__codecompanion_adapter_notified = true
			local log_level = cc_opts.log_level or ""
			if log_level == "DEBUG" then
				vim.schedule(function()
					vim.notify(
						("CodeCompanion adapter: %s (acli=%s)"):format(
							default_adapter,
							(vim.fn.executable("acli") == 1) and "yes" or "no"
						),
						vim.log.levels.DEBUG
					)
				end)
			end
		end

		-- Explicitly set opts fields to ensure they exist and avoid nil errors
		-- Merge with any desired overrides
		local setup_opts = vim.tbl_deep_extend("force", {
			-- Ensure core opts fields exist
			log_level = "DEBUG",
			language = "English", -- Explicit default to avoid nil errors
		}, cc_opts or {})

		local codecompanion = require("codecompanion")
		codecompanion.setup({
			opts = setup_opts,
			strategies = {
				chat = { adapter = default_adapter },
				inline = { adapter = default_adapter },
				workflow = { adapter = default_adapter },
				actions = { adapter = default_adapter },
				cmd = { adapter = default_adapter },
			},
			display = {
				chat = {
					window = {
						layout = "vertical", -- vertical|horizontal|float|buffer
						border = "single",
						height = 0.8,
						width = 0.45,
						relative = "editor",
						opts = {
							breakindent = true,
							cursorcolumn = false,
							cursorline = false,
							foldcolumn = "0",
							linebreak = true,
							list = false,
							signcolumn = "no",
							spell = false,
							wrap = true,
						},
					},
					intro_message = "Welcome to CodeCompanion!",
				},
				action_palette = {
					width = 95,
					height = 10,
					prompt = "Prompt ",
					provider = "default", -- default|telescope|mini_pick|fzf_lua
					opts = {
						show_default_actions = true,
						show_default_prompt_library = true,
					},
				},
				diff = {
					enabled = true,
					provider = "default", -- default|mini_diff
				},
			},
			extensions = {
				history = {
					enabled = true,
					opts = {
						-- Keymap to open history from chat buffer (default: gh)
						keymap = "gh",
						-- Keymap to save the current chat manually (when auto_save is disabled)
						save_chat_keymap = "sc",
						-- Save all chats by default (disable to save only manually using 'sc')
						auto_save = true,
						-- Number of days after which chats are automatically deleted (0 to disable)
						expiration_days = 30,
						-- Picker interface (auto resolved to a valid picker)
						picker = (pcall(require, "snacks") and "snacks" or "telescope"), --- ("telescope", "snacks", "fzf-lua", or "default")
						---Optional filter function to control which chats are shown when browsing
						chat_filter = nil, -- function(chat_data) return boolean end
						-- Customize picker keymaps (optional)
						picker_keymaps = {
							rename = { i = "<C-r>" },
							delete = { i = "<C-x>" },
							duplicate = { i = "<C-y>" },
						},
						---Automatically generate titles for new chats
						auto_generate_title = true,
						title_generation_opts = {
							---Adapter for generating titles (defaults to current chat adapter)
							adapter = title_adapter,
							---Model for generating titles (defaults to current chat model)
							model = title_model,
							---Number of user prompts after which to refresh the title (0 to disable)
							refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
							---Maximum number of times to refresh the title (default: 3)
							max_refreshes = 3,
							format_title = function(original_title)
								-- this can be a custom function that applies some custom
								-- formatting to the title.
								return original_title
							end,
						},
						---On exiting and entering neovim, loads the last chat on opening chat
						continue_last_chat = false,
						---When chat is cleared with `gx` delete the chat from history
						delete_on_clearing_chat = false,
						---Directory path to save the chats
						dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
						---Enable detailed logging for history extension
						enable_logging = false,

						-- Summary system
						summary = {
							-- Keymap to generate summary for current chat (default: "gcs")
							create_summary_keymap = "gcs",
							-- Keymap to browse summaries (default: "gbs")
							browse_summaries_keymap = "gbs",

							generation_opts = {
								adapter = nil, -- defaults to current chat adapter
								model = nil, -- defaults to current chat model
								context_size = 90000, -- max tokens that the model supports
								include_references = true, -- include slash command content
								include_tool_outputs = true, -- include tool execution results
								system_prompt = nil, -- custom system prompt (string or function)
								format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
							},
						},

						-- Memory system (requires VectorCode CLI)
						memory = {
							-- Automatically index summaries when they are generated
							auto_create_memories_on_summary_generation = true,
							-- Path to the VectorCode executable
							vectorcode_exe = "vectorcode",
							-- Tool configuration
							tool_opts = {
								-- Default number of memories to retrieve
								default_num = 10,
							},
							-- Enable notifications for indexing progress
							notify = true,
							-- Index all existing memories on startup
							-- (requires VectorCode 0.6.12+ for efficient incremental indexing)
							index_on_startup = false,
						},
					},
				},
			},
			adapters = {
				acp = {
					-- Keep CodeCompanion's built-in ACP adapters registered.
					-- If we override `adapters.acp` without including these, CodeCompanion can
					-- mis-detect adapter types (e.g. treating `opencode` as HTTP) and crash.
					opencode = "opencode",
					rovodev = function()
						local helpers = require("codecompanion.adapters.acp.helpers")
						return {
							name = "rovodev",
							type = "acp",
							formatted_name = "RovoDev",
							roles = {
								llm = "assistant",
								user = "user",
							},
							opts = {
								verbose_output = true,
							},
							env = (function()
								-- IMPORTANT: ensure the spawned `acli` process inherits a full environment
								local env = vim.fn.environ()
								env.USER_EMAIL = env.USER_EMAIL or vim.env.USER_EMAIL
								env.USER_API_TOKEN = env.USER_API_TOKEN or vim.env.USER_API_TOKEN
								return env
							end)(),

							commands = {
								default = {
									"acli",
									"rovodev",
									"acp",
								},
							},
							defaults = {
								timeout = 60000, -- 60 seconds
								-- Rovo ACP requires this field; keep it empty unless you explicitly want MCP forwarding.
								mcpServers = {},
							},
							parameters = {
								protocolVersion = 1,
								clientCapabilities = {
									fs = { readTextFile = true, writeTextFile = true },
								},
								clientInfo = {
									name = "CodeCompanion.nvim",
									version = "1.0.0",
								},
							},
							handlers = {
								setup = function()
									return true
								end,

								-- Ensure the spawned `acli` process sees these values.
								-- (CodeCompanion also passes env via ACP, but exporting is a safe fallback.)
								auth = function(self)
									-- Prefer values from the adapter env (after replacement), but fall back to
									-- current Neovim environment.
									local email = (self.env_replaced and self.env_replaced.USER_EMAIL)
										or vim.env.USER_EMAIL
									local token = (self.env_replaced and self.env_replaced.USER_API_TOKEN)
										or vim.env.USER_API_TOKEN

									if email and email ~= "" then
										vim.env.USER_EMAIL = email
									end
									if token and token ~= "" then
										vim.env.USER_API_TOKEN = token
									end

									local ok = (email and email ~= "") and (token and token ~= "")
									if not ok then
										local home = vim.env.HOME or ""
										local path = vim.env.PATH or ""
										vim.notify(
											(
												"RovoDev CLI: missing USER_EMAIL/USER_API_TOKEN in environment "
												.. "(HOME="
												.. (home ~= "" and "set" or "missing")
												.. ", PATH="
												.. (path ~= "" and "set" or "missing")
												.. ")"
											),
											vim.log.levels.ERROR
										)
									end
									return ok
								end,

								form_messages = function(self, messages, capabilities)
									return helpers.form_messages(self, messages, capabilities)
								end,
								on_exit = function() end,
							},
						}
					end,
				},
				http = {
					ollama = function()
						-- IMPORTANT: extend the built-in *HTTP* ollama adapter directly.
						-- Using the generic factory (`codecompanion.adapters`).extend here can recurse
						-- back into `config.adapters.http.ollama` and/or mis-detect adapter types.
						return require("codecompanion.adapters.http").extend("ollama", {
							env = { url = "http://localhost:11434" },
							headers = {
								["Content-Type"] = "application/json",
								-- ["Authorization"] = "Bearer ${api_key}"
							},
							parameters = { sync = true },
						})
					end,

					-- Dedicated, non-streaming Ollama adapter used only for chat title generation.
					-- Crucially, its model.default is a *string*, so CodeCompanion won't call it as a function.
					ollama_title = function()
						return require("codecompanion.adapters.http").extend("ollama", {
							name = "ollama_title",
							formatted_name = "Ollama (Title Generation)",
							env = { url = "http://localhost:11434" },
							parameters = { sync = true },
							opts = { stream = false },
							schema = {
								model = {
									default = title_model or "smollm2:135m",
								},
							},
						})
					end,
				},
			},
		})
		
		-- Apply patches after setup to fix any remaining nil value issues
		codecompanion_fix.apply_patches()

		-- Disable file logging to prevent logging to ~/.local/state/nvim/codecompanion.log
		log.set_root(log.new({
			handlers = {
				{
					type = "echo",
					level = vim.log.levels.ERROR,
				},
				{
					type = "notify",
					level = vim.log.levels.WARN,
				},
				-- File handler removed to disable logging conversations
			},
		}))

		-- When leaving a CodeCompanion window (chat/history/actions/etc.) while in Insert mode,
		-- and focusing a real file buffer next, automatically exit Insert mode.
		-- This avoids confusing "still in insert" behavior when you return to code.
		if vim.g.codecompanion_stopinsert_on_file_enter then
			local function is_codecompanion_buf(buf)
				if not buf or not vim.api.nvim_buf_is_valid(buf) then
					return false
				end
				local ft = vim.bo[buf].filetype or ""
				if ft:match("^codecompanion") then
					return true
				end
				local name = vim.api.nvim_buf_get_name(buf)
				return name:find("%[CodeCompanion%]") ~= nil
			end

			local function is_real_file_buf(buf)
				if not buf or not vim.api.nvim_buf_is_valid(buf) then
					return false
				end
				if vim.bo[buf].buftype ~= "" then
					return false
				end
				if not vim.bo[buf].buflisted then
					return false
				end
				local name = vim.api.nvim_buf_get_name(buf)
				return name ~= nil and name ~= ""
			end

			local group = vim.api.nvim_create_augroup("RovoDevCodeCompanionStopInsert", { clear = true })
			local left_codecompanion = false

			vim.api.nvim_create_autocmd("WinLeave", {
				group = group,
				callback = function(ev)
					left_codecompanion = is_codecompanion_buf(ev.buf)
				end,
			})

			vim.api.nvim_create_autocmd("WinEnter", {
				group = group,
				callback = function(ev)
					if not left_codecompanion then
						return
					end
					left_codecompanion = false

					-- `stopinsert` only matters if we actually landed in insert mode.
					if not vim.fn.mode():match("^[iR]") then
						return
					end
					if is_codecompanion_buf(ev.buf) then
						return
					end
					if not is_real_file_buf(ev.buf) then
						return
					end

					vim.schedule(function()
						pcall(vim.cmd, "stopinsert")
					end)
				end,
			})
		end
	end,
}
