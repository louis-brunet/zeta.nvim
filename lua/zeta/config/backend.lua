local M = {}

---@enum zeta.Backend
M.Backend = {
    OPENAI = "openai",
    ZED = "zed",
}

-- ---@alias zeta.Backend "openai"|"zed"

---@class zeta.BackendConfigOpenAi
---@field url string

---@class zeta.BackendOptsOpenAi
---@field url? string

---@class zeta.BackendConfigZed

---@class zeta.BackendOptsZed

---@class zeta.BackendConfig
---@field openai zeta.BackendConfigOpenAi
---@field zed zeta.BackendConfigZed

---@class zeta.BackendOpts
---@field openai? zeta.BackendOptsOpenAi
---@field zed? zeta.BackendOptsZed

return M
