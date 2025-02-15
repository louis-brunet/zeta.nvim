local listener = require("zeta.listener")

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
            if vim.bo[ev.buf].buftype ~= "" then
                return
            end
            if not vim.treesitter.language.get_lang(ev.match) then
                return
            end
            listener.attach(ev.buf)
            vim.notify("zeta attached")
        end,
    })
end

return M
