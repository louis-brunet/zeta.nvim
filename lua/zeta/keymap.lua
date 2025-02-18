local api = require("zeta.api")

local keymap = {}

-- -- TODO: move this to zeta/api.lua
-- local function accept()
--     local editor = require("zeta.editor")
--     local log = require("zeta.log")
--     local edits = vim.b.predicted_edits
--     if not edits or #edits == 0 then
--         vim.notify("no predicted edits available yet")
--         return
--     end
--     vim.api.nvim_buf_clear_namespace(0, editor.INDI_NS, 0, -1)
--     local edit = table.remove(edits, 1)
--     log.debug("ask for edit", edit)
--     editor.ask_for_edit(edit, 0, function()
--         editor.set_edits(0, edits)
--     end)
--     -- vim.iter(edits):map(function(edit)
--     --     -- editor.buf_del_extmark(0, edit.preview.id)
--     -- end)
-- end

---@param bufnr integer
function keymap.attach(bufnr)
    vim.keymap.set("n", "<plug>(zeta-accept)", api.accept, { buffer = bufnr })
end

return keymap
