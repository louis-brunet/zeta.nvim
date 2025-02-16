---@mod zeta-nvim.config.default zeta.nvim default configuration

---@comment default-config:start
---zeta.nvim default configuration
---@class zeta.Config
local default_config = {
    ---@see vim.log.levels
    ---@type integer log level
    _log_level = vim.log.levels.DEBUG,
}
---@comment default-config:end

return default_config
