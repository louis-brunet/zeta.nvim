local M = {}

local ns = vim.api.nvim_create_namespace("zeta.nvim")

---Save predicted edits to given buffer without actually applying them.
---Executing this will set some eol virtual text and inline highlights.
---@param bufnr integer
---@param edits zeta.LineEdit[]
function M.set_edits(bufnr, edits)
    -- TODO: implement this
end

---@param bufnr integer
---@param edit zeta.LineEdit
---@return integer[] ids
function M.show_inlinediff(bufnr, edit)
    local virtlines_id = vim.api.nvim_buf_set_extmark(bufnr, ns, edit.range[2] - 1, 0, {
        hl_eol = true,
        virt_lines = vim.iter(edit.value)
            :map(function(line)
                return { { line, "DiffAdd" } }
            end)
            :totable(),
        line_hl_group = "DiffAdd",
    })
    local hl_eols_id = vim.api.nvim_buf_set_extmark(bufnr, ns, edit.range[1] - 1, 0, {
        end_row = edit.range[2] - 1,
        line_hl_group = "DiffDelete",
    })
    return {
        virtlines_id,
        hl_eols_id,
    }
end

---@param bufnr integer
---@param id integer
function M.buf_del_extmark(bufnr, id)
    vim.api.nvim_buf_del_extmark(bufnr, ns, id)
end

---@param bufnr integer
---@param edit zeta.LineEdit
function M.apply_edit(bufnr, edit)
    vim.api.nvim_buf_set_lines(bufnr, edit.range[1] - 1, edit.range[2], false, edit.value)
end

---@param edit zeta.LineEdit
---@param bufnr? integer
---@param callback? fun()
-- TODO: use nvim-nio instead of callback hell
function M.ask_for_edit(edit, bufnr, callback)
    bufnr = bufnr or 0
    local ids = M.show_inlinediff(bufnr, edit)
    vim.api.nvim_win_set_cursor(0, { edit.range[1], 0 })
    vim.cmd.normal({ bang = true, args = { "zz" } })
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
            M.apply_edit(bufnr, edit)
            -- TODO: set undo mark
        end
        vim.iter(ids):map(function(id)
            M.buf_del_extmark(bufnr, id)
        end)
        if callback then
            callback()
        end
    end)
end

return M
