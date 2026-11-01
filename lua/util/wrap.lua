-- Soft wrap ("fit to screen") helper.
--
-- `wrap` is a window-local option, so a plain `:set wrap` only affects the
-- current window and is lost on window/buffer switches.
--
-- render-markdown.nvim also re-applies its `win_options.wrap` value on every
-- update (see lua/render-markdown/core/ui.lua), which silently undoes a
-- manual toggle inside rendered markdown buffers. To avoid that fight, the
-- preference is stored per buffer (b:wrap_fit) and re-applied through the
-- plugin's `on.render` / `on.clear` hooks (see editor-render-markdown.lua).

local M = {}

---@param buf integer
---@return boolean? nil when the buffer was never toggled
function M.get(buf)
	local ok, value = pcall(vim.api.nvim_buf_get_var, buf, "wrap_fit")
	if ok then
		return value
	end
	return nil
end

---@param buf integer
---@param enabled boolean
function M.set(buf, enabled)
	pcall(vim.api.nvim_buf_set_var, buf, "wrap_fit", enabled)
end

---Apply the stored preference of a buffer to every window showing it.
---@param buf integer
function M.apply_to_buffer(buf)
	local enabled = M.get(buf)
	if enabled == nil then
		return
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
			vim.api.nvim_set_option_value("wrap", enabled, { win = win })
		end
	end
end

---Apply the stored preference of a buffer to a single window.
---@param win? integer window handle, defaults to the current window
function M.apply(win)
	local winnr = win or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(winnr) then
		return
	end
	M.apply_to_buffer(vim.api.nvim_win_get_buf(winnr))
end

---Toggle soft wrap for the current buffer (and every window showing it).
---@return boolean the new state
function M.toggle()
	local winnr = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(winnr)
	local enabled = not vim.api.nvim_get_option_value("wrap", { win = winnr })

	M.set(buf, enabled)
	M.apply_to_buffer(buf)

	vim.notify(("Line wrap %s"):format(enabled and "on" or "off"), vim.log.levels.INFO)
	return enabled
end

---Register autocmds that re-apply the preference in new windows.
function M.setup()
	local group = vim.api.nvim_create_augroup("UserWrap", { clear = true })
	vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter" }, {
		group = group,
		desc = "Apply the per buffer wrap preference",
		callback = function(args)
			M.apply_to_buffer(args.buf)
		end,
	})
end

return M
