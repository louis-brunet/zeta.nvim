local M = {}

local ns = vim.api.nvim_create_namespace("zeta.nvim")

---@param edit zeta.LineEdit
---@param bufnr? integer
---@return integer[] ids
function M.show_edit_preview(edit, bufnr)
    bufnr = bufnr or 0
    local virtlines_id = vim.api.nvim_buf_set_extmark(bufnr, ns, edit.range[2] - 1, 0, {
        hl_eol = true,
        virt_lines = vim.iter(edit.value):map(function(line)
            return { { line, "DiffAdd" } }
        end):totable(),
        line_hl_group = "DiffAdd",
    })
    local hl_eols_id = vim.api.nvim_buf_set_extmark(bufnr, ns, edit.range[1] -1, 0, {
        end_row = edit.range[2] - 1,
        line_hl_group = "DiffDelete",
    })
    return {
        virtlines_id,
        hl_eols_id,
    }
end

function M.clear_all_virtual_lines(bufnr)
    bufnr = bufnr or 0
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function M.clear_extmark(id, bufnr)
    bufnr = bufnr or 0
    vim.api.nvim_buf_del_extmark(bufnr, ns, id)
end

-- M.clear_all_virtual_lines()
-- M.show_edit_preview({
--     range = { 3, 3 },
--     value = { "edit here" },
-- })

return M
