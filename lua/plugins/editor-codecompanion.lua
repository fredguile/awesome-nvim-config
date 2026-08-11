return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ikatyang/tree-sitter-yaml",
		"ravitemer/codecompanion-history.nvim",
		{
			-- Full default config (applies to plain *.md files too) lives in
			-- editor-render-markdown.lua; lazy.nvim deep-merges `opts` across spec
			-- fragments for the same plugin, so we only declare the minimal overrides
			-- that are actually specific to rendering inside a CodeCompanion buffer.
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				overrides = {
					filetype = {
						-- CodeCompanion renders its chat in a side panel that's only ~33% of
						-- the screen width, so tables need a more compact layout to avoid
						-- ugly wrapping/truncation. `normal` skips the extra top/bottom
						-- border lines (`cell = "trimmed"` is already the root default).
						codecompanion = {
							pipe_table = {
								style = "normal",
							},
							-- Chat messages are mostly prose, not tables, so keep soft-wrap
							-- on even in rendered view here (root config turns wrap off for
							-- rendered markdown by default, to protect wide tables in *.md
							-- files, which doesn't apply the same way in a chat panel).
							win_options = {
								wrap = { rendered = true },
							},
						},
					},
				},
			},
		},
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
				pcall(vim.fn.mkdir, dir, "p")

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
		local log = require("codecompanion.utils.log")

		local function preferred_acp_adapter()
			-- Prefer the Rovo ACP adapter when the CLI is available.
			-- Fall back to CodeCompanion's built-in OpenCode ACP adapter otherwise.
			return (vim.fn.executable("rovo") == 1) and "rovo" or "opencode"
		end

		local default_adapter = preferred_acp_adapter()

		local codecompanion = require("codecompanion")
		codecompanion.setup({
			opts = {
				language = "English",
			},
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
							refresh_every_n_prompts = 5, -- refresh title every 5 user messages
							max_refreshes = 2,           -- but at most twice
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

						-- Memory system (requires the VectorCode CLI, which isn't installed here — leave disabled).
						memory = {
							auto_create_memories_on_summary_generation = false,
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
					claude_code = "claude_code",
					rovo = function()
						local helpers = require("codecompanion.adapters.acp.helpers")
						return {
							name = "rovo",
							type = "acp",
							formatted_name = "Atlassian Rovo",
							roles = {
								llm = "assistant",
								user = "user",
							},
							opts = {
								verbose_output = true,
							},
							commands = {
								default = {
									"rovo",
									"acp",
								},
							},
							defaults = {
								timeout = 60000, -- 60 seconds
								-- Rovo ACP requires this field; keep it empty unless you explicitly want MCP forwarding.
								mcpServers = {},
								-- Matches the "product-login" authMethod the `rovo acp` server advertises.
								-- Since `rovo auth login` already stores an OAuth session in the keychain,
								-- CodeCompanion's default ACP auth flow can send this RPC and it succeeds
								-- immediately with no custom auth handler needed.
								auth_method = "product-login",
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

								form_messages = function(self, messages, capabilities)
									return helpers.form_messages(self, messages, capabilities)
								end,
								on_exit = function() end,
							},
						}
					end,
				},
			},
		})

		-- Disable file logging to prevent logging conversations to disk
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
		do
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
