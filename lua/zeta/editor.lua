local state = require("zeta.state")
local log = require("zeta.log")

local M = {}

M.INDI_NS = vim.api.nvim_create_namespace("zeta.nvim.indicator")
M.PREVIEW_NS = vim.api.nvim_create_namespace("zeta.nvim")

M.choice = {
    ACCEPT = 1, -- Yes
    LAST = 2, -- Last
    REJECT = 3, -- No
}

---@param bufnr integer
---@param prediction zeta.Prediction
function M.set_prediction(bufnr, prediction)
    if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end
    local first_edit = prediction.edits[1]
    if not first_edit then
        log.debug("ignore prediction without any edits")
        return
    end
    -- TODO: show indicator
    state.buffers[bufnr].prediction = prediction
    vim.api.nvim_buf_clear_namespace(bufnr, M.INDI_NS, 0, -1)
    vim.api.nvim_buf_set_extmark(bufnr, M.INDI_NS, first_edit.range[1] - 1, 0, {
        virt_text = {
            { " Predicted Edit [Press gy to preview] " },
        },
        virt_text_pos = "right_align",
    })
end

---@param bufnr integer
function M.clear_prediction(bufnr)
    state.buffers[bufnr].prediction = nil
    vim.api.nvim_buf_clear_namespace(bufnr, M.INDI_NS, 0, -1)
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
---@param callback? fun(choice: integer)
-- TODO: use nvim-nio instead of callback hell
function M.ask_for_edit(edit, bufnr, callback)
    bufnr = bufnr or 0
    local winid = vim.api.nvim_get_current_win()
    -- show inline diff
    local ext_ids = {
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
                { " Apply Edit? (Y)es, (L)ast, [N]o, (Q)uit " },
            },
            virt_text_pos = "right_align",
        }),
    }
    vim.api.nvim_win_set_cursor(0, { edit.range[1], 0 })
    vim.cmd.normal({ bang = true, args = { "zz" } })
    vim.cmd.redraw()
    if not pcall(vim.api.nvim__redraw, { win = winid, flush = true }) then
        -- TODO: if redraw failed, screen state must be broken
        -- check ok and do something with it.
        log.debug("nvim__redraw failed")
    end
    callback = callback or function() end
    vim.schedule(function()
        local choice = vim.fn.confirm("Apply edit?", "&Yes\n&Last\n&No\n&Quit", 3, "Question")
        vim.iter(ext_ids):map(function(id)
            M.buf_hide_inelinediffs(bufnr, id)
        end)
        callback(choice)
    end)
end

---Shows inline diff of prediction and asks for accept
---@param bufnr integer
---@param prediction zeta.Prediction
function M.preview_prediction(bufnr, prediction)
    log.debug("preview prediction")
    assert(#prediction.edits > 0, "prediction needs to have at least 1 line edit")
    local edits = prediction.edits
    M.clear_prediction(bufnr)
    local function ask(edit)
        M.ask_for_edit(edit, bufnr, function(choice)
            vim.api.nvim_buf_clear_namespace(bufnr, M.INDI_NS, 0, -1)
            if choice == M.choice.ACCEPT then
                M.apply_edit(bufnr, edit)
                local next_edit = table.remove(edits, 1)
                if next_edit then
                    ask(next_edit)
                end
            elseif choice == M.choice.LAST then
                M.apply_edit(bufnr, edit)
            elseif choice == M.choice.REJECT then
                local next_edit = table.remove(edits, 1)
                if next_edit then
                    ask(next_edit)
                end
            end
        end)
    end
    ask(table.remove(edits, 1))
end

return M
