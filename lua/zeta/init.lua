local M = {}

local function hl_setup()
    vim.api.nvim_set_hl(0, "ZetaDiffAdd", { link = "DiffAdd" })
    vim.api.nvim_set_hl(0, "ZetaDiffDelete", { link = "DiffDelete" })
end

---@param opts? zeta.Opts
function M.setup(opts)
    vim.g.zeta_nvim = opts
    hl_setup()
end

return M
