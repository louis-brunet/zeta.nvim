---@mod zeta-nvim.config.default zeta.nvim default configuration

---@comment default-config:start
---zeta.nvim default configuration
---@class zeta.Config
local default_config = {
    ---@see vim.log.levels
    ---@type integer log level
    _log_level = vim.log.levels.DEBUG,
    ---@type zeta.Backend
    backend = "openai",
    ---@type zeta.BackendConfig
    backend_config = {
        openai = {
            url = "http://localhost:7000/v1/completions",
        },
        zed = {
            -- url = "localhost:7000/predict_edits/v2"
        },
    },
}
---@comment default-config:end

return default_config
