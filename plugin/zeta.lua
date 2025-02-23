-- require("zeta.autocmd").setup()

vim.api.nvim_set_hl(0, "ZetaDiffAdd", { link = "DiffAdd" })
vim.api.nvim_set_hl(0, "ZetaDiffDelete", { link = "DiffDelete" })

local ok_sense, _ = pcall(require, "sense")
if not ok_sense then
    return
end
local sense_api = require("sense.api")
local sense_ui = require("sense.ui")

local JumpWithIndicator = sense_ui.virtualtext.create({
    name = "zeta_nvim",
    on_init = function(_self)
        -- TODO: register autocommand to listen to prediction update
    end,
    render_lines = function(wininfo)
        local bufstate = require("zeta.state").buffers[wininfo.bufnr]
        if not bufstate then
            return
        end
        local prediction = bufstate.prediction
        if not prediction then
            return
        end
        local above = (function()
            local lnum = prediction.edits[1].range[1]
            if lnum >= wininfo.topline then
                return
            end
            local cursor_row = vim.api.nvim_win_get_cursor(wininfo.winid)[1]
            local _distance = cursor_row - lnum
            local line = (" ↑ Jump with [gy] ")
            return { lines = { line }, highlights = {} }
        end)()
        local below = (function()
            local lnum = prediction.edits[1].range[1]
            if lnum <= wininfo.botline then
                return
            end
            local cursor_row = vim.api.nvim_win_get_cursor(wininfo.winid)[1]
            local _distance = lnum - cursor_row
            local line = (" ↓ Jump with [gy] ")
            return { lines = { line }, highlights = {} }
        end)()
        return {
            above = above,
            below = below,
        }
    end
})

sense_api.register_renderer(JumpWithIndicator)
