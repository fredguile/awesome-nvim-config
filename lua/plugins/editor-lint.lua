return {

	{ -- Linting
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "markdownlint" },
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
			}

			-- To allow other plugins to add linters to require('lint').linters_by_ft,
			-- instead set linters_by_ft like this:
			-- lint.linters_by_ft = lint.linters_by_ft or {}
			-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
			--
			-- However, note that this will enable a set of default linters,
			-- which will cause errors unless these tools are available:
			-- {
			--   clojure = { "clj-kondo" },
			--   dockerfile = { "hadolint" },
			--   inko = { "inko" },
			--   janet = { "janet" },
			--   json = { "jsonlint" },
			--   markdown = { "vale" },
			--   rst = { "vale" },
			--   ruby = { "ruby" },
			--   terraform = { "tflint" },
			--   text = { "vale" }
			-- }
			--
			-- You can disable the default linters by setting their filetypes to nil:
			-- lint.linters_by_ft['clojure'] = nil
			-- lint.linters_by_ft['dockerfile'] = nil
			-- lint.linters_by_ft['inko'] = nil
			-- lint.linters_by_ft['janet'] = nil
			-- lint.linters_by_ft['json'] = nil
			-- lint.linters_by_ft['markdown'] = nil
			-- lint.linters_by_ft['rst'] = nil
			-- lint.linters_by_ft['ruby'] = nil
			-- lint.linters_by_ft['terraform'] = nil
			-- lint.linters_by_ft['text'] = nil

			-- Linting strategy:
			-- - Do NOT lint on BufEnter (opening files from lazygit/snacks should be instant)
			-- - Lint only on explicit saves (BufWritePost)
			-- - Keep a :Lint command for manual linting
			-- - Add a small debounce + guardrails for huge files / special buffers
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			local debounce_ms = 150
			local max_file_size = 1024 * 1024 -- 1 MiB
			local timers = {}

			local function should_lint(bufnr)
				bufnr = bufnr or 0
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return false
				end

				local bt = vim.bo[bufnr].buftype
				if bt ~= "" then
					return false
				end

				if not vim.bo[bufnr].modifiable then
					return false
				end

				local name = vim.api.nvim_buf_get_name(bufnr)
				if not name or name == "" then
					return false
				end

				-- Skip huge files (eslint/markdownlint can get expensive)
				local ok, size = pcall(vim.fn.getfsize, name)
				if ok and type(size) == "number" and size > max_file_size then
					return false
				end

				return true
			end

			local function try_lint_debounced(bufnr)
				if not should_lint(bufnr) then
					return
				end

				-- Per-buffer debounce to avoid repeated triggers (e.g. multiple writes)
				timers[bufnr] = timers[bufnr] or vim.uv.new_timer()
				local t = timers[bufnr]
				t:stop()
				t:start(debounce_ms, 0, function()
					vim.schedule(function()
						if should_lint(bufnr) then
							lint.try_lint(nil, { bufnr = bufnr })
						end
					end)
				end)
			end

			vim.api.nvim_create_user_command("Lint", function()
				local bufnr = vim.api.nvim_get_current_buf()
				try_lint_debounced(bufnr)
			end, { desc = "Run nvim-lint for the current buffer" })

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				group = lint_augroup,
				callback = function(args)
					try_lint_debounced(args.buf)
				end,
			})
		end,
	},
}
