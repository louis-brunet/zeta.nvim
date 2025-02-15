local listener = require("zeta.listener")

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "lua", "rust" },
        callback = function(ev)
            if vim.bo[ev.buf].buftype ~= "" then
                return
            end
            listener.attach(ev.buf)
        end,
    })
end

return M
