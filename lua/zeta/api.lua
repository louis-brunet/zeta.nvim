local editor = require("zeta.editor")
local common = require("zeta.common")
local state = require("zeta.state")
local log = require("zeta.log")

local M = {}

function M.accept()
    log.debug("api.accept")
    local bufnr = vim.api.nvim_get_current_buf()
    local prediction = state.buffers[bufnr].prediction
    if prediction then
        editor.preview_prediction(bufnr, prediction)
    else
        vim.notify("no prediction available")
        common.request_predict_completion()
    end
end

return M
