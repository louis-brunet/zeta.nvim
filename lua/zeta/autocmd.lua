local keymap = require("zeta.keymap")
local listener = require("zeta.listener")
local log = require("zeta.log")

local M = {}

local augroup = vim.api.nvim_create_augroup("zeta.nvim", { clear = true })

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function(ev)
            if vim.bo[ev.buf].buftype ~= "" then
                return
            end
            -- zeta.nvim requires treesitter parser to be available on current buffer
            if not vim.treesitter.language.get_lang(ev.match) then
                return
            end
            if not listener.attach(ev.buf) then
                return
            end
            keymap.attach(ev.buf)
            -- vim.api.nvim_create_autocmd("CursorMoved", {
            --     callback = function(_ev)
            --         -- clear previous predicted edits when cursor moved out of scope
            --     end
            -- })
            log.debug("attached to buffer", ev.buf)
            vim.notify("zeta attached")
        end,
    })
end

return M
