-- CodeCompanion Bug Fixes
-- Upstream bugs patched at runtime to avoid forking the plugin.
--
-- Bug 1: update_metadata nil self.ui
--   update_metadata() accesses self.ui.tokens unconditionally but is called from async
--   ACP paths before self.ui is initialized → "attempt to index field 'ui' (a nil value)"
--
-- Bug 2: "Lua failed to grow stack" in nvim_exec_autocmds
--   acp/init.lua fires ACPSessionPre with adapter_modified (full adapter object: functions,
--   full env, deeply nested tables) as autocmd data → Neovim's Lua→Vimscript serializer
--   exhausts the C stack. Fix: strip adapter_modified before the call.
--
-- Bug 3: Double acli process spawn → "Failed to create session"
--   create_acp_connection (async, at chat open) and ensure_connection (on submit) race on
--   the same Connection object. Second caller sees is_ready()=false and re-spawns acli.
--   Fix: guard connect_and_authenticate against re-spawning; make ensure_connection wait.

local M = {}

-- Patch a module's method, handling the case where the module may not be loaded yet.
-- Uses package.preload wrapping so the patch is applied whenever the module is first required.
local function patch_module(module_path, patcher)
  if package.loaded[module_path] then
    -- Already loaded — patch immediately.
    patcher(package.loaded[module_path])
  else
    -- Not yet loaded — wrap the loader so patcher runs on first require().
    local original_loader = package.preload[module_path]
    package.preload[module_path] = function(...)
      -- Load the real module (via original preload or searchers).
      local mod
      if original_loader then
        mod = original_loader(...)
      else
        -- Fall back to the standard searchers (minus preload, which we've replaced).
        -- In LuaJIT (Neovim) the table is package.loaders; in Lua 5.2+ it's package.searchers.
        local searchers = package.searchers or package.loaders
        for i = 2, #searchers do
          local loader = searchers[i](module_path)
          if type(loader) == "function" then
            mod = loader(module_path)
            break
          end
        end
      end
      if mod ~= nil then
        package.loaded[module_path] = mod
        patcher(mod)
      end
      return mod
    end
  end
end

function M.apply_patches()
  -- Patch the Chat class to handle nil ui in update_metadata
  -- update_metadata accesses self.ui.tokens unconditionally; called from async ACP paths
  -- before self.ui is initialized.
  patch_module("codecompanion.interactions.chat", function(chat)
    if chat.Chat and chat.Chat.update_metadata then
      local orig = chat.Chat.update_metadata
      chat.Chat.update_metadata = function(self)
        if not self or not self.ui then return end
        return orig(self)
      end
    end
  end)

  -- Patch Connection:connect_and_authenticate to guard against double process spawning.
  --
  -- Root cause: create_acp_connection (async, at chat open) and ensure_connection (on submit)
  -- both call connect_and_authenticate() on the same Connection object.  The first sets
  -- _state.handle and begins initialize/auth.  The second sees is_ready()=false and calls
  -- start_agent_process() again, spawning a duplicate acli process that races for session/new.
  --
  -- Fix (part 1): guard Connection:connect_and_authenticate and Connection:ensure_session
  -- against concurrent calls on the same object.
  patch_module("codecompanion.acp", function(Connection)
    -- Guard connect_and_authenticate: if a process is already starting, don't spawn another.
    if Connection and Connection.connect_and_authenticate then
      local orig = Connection.connect_and_authenticate
      Connection.connect_and_authenticate = function(self)
        if self._state and self._state.handle then
          if self:is_ready() then return self end
          -- Mid-initialization: don't re-spawn. Return nil so ensure_connection
          -- (patched below) can wait for is_ready() instead of erroring.
          return nil
        end
        return orig(self)
      end
    end

    -- Guard ensure_session: if a session is already being established concurrently,
    -- wait for it rather than calling _establish_session() a second time.
    -- Uses a simple _establishing flag to detect concurrent entry.
    if Connection and Connection.ensure_session then
      local orig_ensure_session = Connection.ensure_session
      Connection.ensure_session = function(self)
        -- Already have a session — fast path.
        if self.session_id then return true end
        -- Another coroutine is establishing the session — wait for it.
        if self._establishing_session then
          vim.wait(60000, function() return self.session_id ~= nil end, 10)
          return self.session_id ~= nil
        end
        -- Mark as in-progress and run the original.
        self._establishing_session = true
        local ok = orig_ensure_session(self)
        self._establishing_session = false
        return ok
      end
    end
  end)

  -- Fix (part 2): patch ensure_connection in ACPHandler to wait for a mid-init connection
  -- rather than treating nil from connect_and_authenticate as a hard error.
  patch_module("codecompanion.interactions.chat.acp.handler", function(ACPHandler)
    if ACPHandler and ACPHandler.ensure_connection then
      local orig = ACPHandler.ensure_connection
      ACPHandler.ensure_connection = function(self)
        -- Fast path: already ready.
        if self.chat.acp_connection and self.chat.acp_connection:is_ready() then
          return true
        end
        -- If a connection exists but is mid-initialization, wait for it via vim.wait.
        -- vim.wait processes events each poll, so the async coroutine can make progress.
        if self.chat.acp_connection and self.chat.acp_connection._state
          and self.chat.acp_connection._state.handle then
          local timeout_ms = 60000
          vim.wait(timeout_ms, function()
            return self.chat.acp_connection:is_ready()
          end, 10)
          if self.chat.acp_connection:is_ready() then
            local utils = require("codecompanion.utils")
            local watch = require("codecompanion.interactions.shared.watch")
            self.chat:update_metadata()
            watch.enable()
            utils.fire("ACPConnected", { bufnr = self.chat.bufnr })
            return true
          end
          return false
        end
        -- Fresh connection — use original path.
        return orig(self)
      end
    end
  end)

  -- Patch utils.fire to strip deeply-nested/non-serializable fields from autocmd data.
  --
  -- Root cause: acp/init.lua passes `adapter_modified` (the full adapter object — containing
  -- Lua functions, the complete process environment, and deeply nested tables) as the `data`
  -- argument to nvim_exec_autocmds("User", ...).  Neovim's Lua→Vimscript serializer has to
  -- walk the entire table and exhausts the Lua C stack, producing:
  --   "Invalid 'data': Lua failed to grow stack"
  --
  -- Fix: intercept utils.fire and remove `adapter_modified` from the data table before the
  -- call reaches nvim_exec_autocmds.  No external listener ever reads adapter_modified from
  -- the ACPSessionPre event, so this is safe.
  patch_module("codecompanion.utils", function(utils)
    if utils and utils.fire then
      local orig = utils.fire
      utils.fire = function(event, opts)
        if opts and opts.adapter_modified ~= nil then
          local safe_opts = {}
          for k, v in pairs(opts) do
            if k ~= "adapter_modified" then safe_opts[k] = v end
          end
          opts = safe_opts
        end
        return orig(event, opts)
      end
    end
  end)
end

return M
