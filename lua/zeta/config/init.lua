local default_config = require("zeta.config.default")

---@class zeta.Opts

---@type zeta.Opts
local opts = vim.g.zeta_nvim or {}

local config = vim.tbl_deep_extend("force", default_config, opts)
---@cast config zeta.Config

return config
