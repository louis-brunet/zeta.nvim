-- WHO TF NAMED THIS FILE???



















































local editor = require("zeta.editor")

local M = {}

---@class zeta.LineRange
---@field [1] integer start line number
---@field [2] integer end line number

---@class zeta.LineEdit
---@field value string[]
---@field range zeta.LineRange

---@param old string original text (line-wise)
---@param new string predicted text (line-wise)
---@param offset integer line offset from original text
---@return zeta.LineEdit[]
function M.compute_edits(old, new, offset)
    ---@type zeta.LineEdit[]
    local edits = {}
    local new_lines = vim.split(new, "\n", { plain = true })
    vim.diff(old, new, {
        on_hunk = function(start_a, count_a, start_b, count_b)
            local end_a = start_a + count_a - 1
            local end_b = start_b + count_b - 1
            ---@type zeta.LineEdit
            local edit = {
                value = vim.list_slice(
                    new_lines,
                    start_b,
                    end_b
                ),
                range = {
                    offset + start_a,
                    offset + end_a,
                }
            }
            table.insert(edits, edit)
            return 1
        end
    })
    return edits
end

---@param edit zeta.LineEdit
---@param bufnr? integer
function M.apply_edit(edit, bufnr)
    bufnr = bufnr or 0
    vim.api.nvim_buf_set_lines(bufnr, edit.range[1] - 1, edit.range[2], false, edit.value)
end

---@param edit zeta.LineEdit
---@param bufnr? integer
---@param callback? fun()
-- TODO: use nvim-nio instead of callback hell
function M.ask_for_edit(edit, bufnr, callback)
    bufnr = bufnr or 0
    local ids = editor.show_edit_preview(edit, bufnr)
    vim.api.nvim_win_set_cursor(0, { edit.range[1], 0 })
    vim.cmd.normal({ bang = true, args = { "zz" }})
    vim.cmd.redraw()
    -- TODO: if redraw failed, screen state must be broken
    -- check ok and do something with it.
    local _ok = pcall(vim.api.nvim__redraw, {
        win = vim.api.nvim_get_current_win(),
        flush = true,
    })
    vim.schedule(function()
        local choice = vim.fn.confirm("Apply edit?", "&Yes\n&No", 2, "Question")
        if choice == 1 then
            M.apply_edit(edit, bufnr)
            -- TODO: set undo mark
        end
        vim.iter(ids):map(function(id)
            editor.clear_extmark(id, bufnr)
        end)
        if callback then
            callback()
        end
    end)
end

local a = [[
---@param old string original text (line-wise)
---@param new string predicted text (line-wise)
---@param offset integer line offset from original text
---@return zeta.LineEdit[]
function M.compute_edits(old, new, offset)
    ---@type zeta.LineEdit[]
    local edits = {}
    local new_lines = vim.split(old, "\n", { plain = true })
    vim.diff(old, new, {
]]
local b = [[
---@param old string original text (line-wise)
---@param new string predicted text (line-wise)
---@param offset integer line offset from original text
---@return zeta.LineEdit[]
function M.asdfas(old, offset)
    ---@type zeta.ineEdit[]
    local edits = {}
    local new_lines = vim.split(old, "\n", { plain = true })
    vim.iff(old, new, {
]]
local edits = M.compute_edits(a, b, 64)
M.ask_for_edit(edits[1], 0, function()
    M.ask_for_edit(edits[2])
end)

return M
