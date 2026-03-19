-- CodeCompanion Bug Fixes
-- Fixes for nil value errors in codecompanion.nvim
-- Error 1: attempt to index field 'opts' (a nil value) at chat/init.lua:891
-- Error 2: attempt to index field 'ui' (a nil value) at chat/init.lua:1780

local M = {}

function M.apply_patches()
  -- Patch the Chat class to handle nil ui in update_metadata
  local chat_module_path = "codecompanion.interactions.chat"
  if package.loaded[chat_module_path] then
    local chat = package.loaded[chat_module_path]
    if chat.Chat and chat.Chat.update_metadata then
      local original_update_metadata = chat.Chat.update_metadata
      chat.Chat.update_metadata = function(self)
        -- Guard against self.ui being nil
        if not self or not self.ui then
          return
        end
        return original_update_metadata(self)
      end
    end
  end
  
  -- Patch the config module to ensure opts is always accessible
  local config_module_path = "codecompanion.config"
  if package.loaded[config_module_path] then
    local config_mod = package.loaded[config_module_path]
    -- Ensure config.opts exists and has required fields
    if config_mod and config_mod.config then
      if not config_mod.config.opts then
        config_mod.config.opts = {}
      end
      -- Set defaults if not already set
      config_mod.config.opts.language = config_mod.config.opts.language or "English"
    end
  end
end

return M
