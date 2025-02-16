local log = require("zeta.log")

local M = {}

M.INDI_NS = vim.api.nvim_create_namespace("zeta.nvim.indicator")
M.PREVIEW_NS = vim.api.nvim_create_namespace("zeta.nvim")

---Save predicted edits to given buffer without actually applying them.
---Executing this will set some eol virtual text and inline highlights.
---@param bufnr integer
---@param edits zeta.LineEdit[]
function M.set_edits(bufnr, edits)
    if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end
    ---@type zeta.LineEdit[]
    vim.b[bufnr].predicted_edits = edits
    local first_edit = edits[1]
    vim.api.nvim_buf_clear_namespace(bufnr, M.INDI_NS, 0, -1)
    if first_edit then
        vim.api.nvim_buf_set_extmark(bufnr, M.INDI_NS, first_edit.range[1] - 1, 0, {
            virt_text = {
                { "Predicted Edit [Press gy to accept]" },
            },
        })
    end
end

---@param bufnr integer
---@param edit zeta.LineEdit
---@return integer[] extmark_ids
function M.show_inlinediff(bufnr, edit)
    return {
        vim.api.nvim_buf_set_extmark(bufnr, M.PREVIEW_NS, edit.range[2] - 1, 0, {
            hl_eol = true,
            virt_lines = vim.iter(edit.value)
                :map(function(line)
                    return { { line, "ZetaDiffAdd" } }
                end)
                :totable(),
            line_hl_group = "ZetaDiffAdd",
        }),
        vim.api.nvim_buf_set_extmark(bufnr, M.PREVIEW_NS, edit.range[1] - 1, 0, {
            end_row = edit.range[2] - 1,
            line_hl_group = "ZetaDiffDelete",
        }),
        vim.api.nvim_buf_set_extmark(bufnr, M.PREVIEW_NS, edit.range[1] - 1, 0, {
            virt_text = {
                -- { "Apply Edit? (Y)es, [N]o, (S)kip, (Q)uit" },
                { "Apply Edit? (Y)es, [N]o" },
            },
        }),
    }
end

---@param bufnr integer
---@param id integer
function M.buf_hide_inelinediffs(bufnr, id)
    vim.api.nvim_buf_del_extmark(bufnr, M.PREVIEW_NS, id)
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
    local winid = vim.api.nvim_get_current_win()
    local ext_ids = M.show_inlinediff(bufnr, edit)
    vim.api.nvim_win_set_cursor(0, { edit.range[1], 0 })
    vim.cmd.normal({ bang = true, args = { "zz" } })
    vim.cmd.redraw()
    if not pcall(vim.api.nvim__redraw, { win = winid, flush = true }) then
        -- TODO: if redraw failed, screen state must be broken
        -- check ok and do something with it.
        log.debug("nvim__redraw failed")
    end
    vim.schedule(function()
        local choice = vim.fn.confirm("Apply edit?", "&Yes\n&No", 2, "Question")
        if choice == 1 then
            M.apply_edit(bufnr, edit)
            -- TODO: set undo mark
        end
        vim.iter(ext_ids):map(function(id)
            M.buf_hide_inelinediffs(bufnr, id)
        end)
        if callback then
            callback()
        end
    end)
end

return M
