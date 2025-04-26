local default_config = require("zeta.config.default")

---@class zeta.Opts
---@field backend? zeta.Backend backend to use for completions
---@field backend_config? zeta.BackendOpts backend-specific configurations
---@field cancel_pending_requests? boolean cancel pending requests when requesting a new prediction

---@type zeta.Opts
local opts = vim.g.zeta_nvim or {} --[[@as zeta.Opts]]

-- TODO: isn't this only ran on the first `require`? what if the user calls `setup` after this
-- module has been required once?
local config = vim.tbl_deep_extend("force", default_config, opts)
---@cast config zeta.Config

return config
