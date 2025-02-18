-- YES I'M TERRIBLE ON NAMING FILES

local log = require("zeta.log")
local state = require("zeta.state")
local uv = vim.uv

local M = {}

-- NOTE: text sync code is heavily inspired (copied) from Neovim's internal
-- LSP textDocument/didChange implementation

local TEXTCHANGE_DEBOUNCE = 200

---@class zeta.EditorEvent

---@class zeta.event.LineEditEvent: zeta.LineEdit
---@field path string
---@field old_lines string[]
---@field a_ctx_lines string[]
---@field b_ctx_lines string[]

-- Adjust debounce time by taking time of last didChange notification into
-- consideration. If the last didChange happened more than `debounce` time ago,
-- debounce can be skipped and otherwise maybe reduced.
--
-- This turns the debounce into a kind of client rate limiting
--
---@param debounce integer
---@param last_flush integer
---@return number
local function next_debounce(debounce, last_flush)
    if debounce == 0 then
        return 0
    end
    local ns_to_ms = 0.000001
    if not last_flush then
        return debounce
    end
    local now = uv.hrtime()
    local ms_since_last_flush = (now - last_flush) * ns_to_ms
    return math.max(debounce - ms_since_last_flush, 0)
end

---@param buf_state zeta.BufState
local function reset_timer(buf_state)
    local timer = buf_state.timer
    if timer then
        buf_state.timer = nil
        if not timer:is_closing() then
            timer:stop()
            timer:close()
        end
    end
end

local MAX_HUNK_HEIGHT = 10

---Merges two line-edits into one.
---Returns nil when two edits can't be merged
---@param a zeta.LineEdit
---@param b zeta.LineEdit
---@return zeta.LineEdit?
local function merge_line_edits(a, b)
    local aos, aol, ans, anl = a.range[1], a.range[2], a.range[1], a.range[1] + #a.value
    local bos, bol, ___, ___ = b.range[1], b.range[2], b.range[1], b.range[1] + #b.value
    local a_hunk_height = anl - ans + aol - aos
    -- NOTE: Don't merge when hunk height is too long.
    -- Long hunk might exceed the token limit
    if a_hunk_height >= MAX_HUNK_HEIGHT then
        return
    end
    local mergeable = anl >= bos and bol >= ans
    if not mergeable then
        return
    end
    ---@type string[]
    local lines = vim.iter({
        vim.list_slice(a.value, 1, bos - ans),
        b.value,
        vim.list_slice(a.value, bol - (ans - 1)),
    })
        :flatten()
        :totable()
    ---@type zeta.LineRange
    local range = {
        aos - math.max(ans - bos, 0),
        aol + math.max(bol - anl, 0),
    }
    return {
        range = range,
        value = lines,
    }
end

---@param bufnr integer
---@param firstline integer
---@param lastline integer
---@param new_lastline integer
---@param buf_state zeta.BufState
local function handle_changes(bufnr, firstline, lastline, new_lastline, buf_state)
    if not buf_state.needs_flush then
        return
    end
    buf_state.last_flush = uv.hrtime()
    buf_state.needs_flush = false
    log.debug("nvim_buf_lines_event", "fl:", firstline, "ll:", lastline, "nl:", new_lastline)
    local old_lines = buf_state.old_lines
    local new_lines = vim.iter({
        vim.list_slice(buf_state.old_lines, 1, firstline),
        vim.api.nvim_buf_get_lines(bufnr, firstline, new_lastline, false),
        vim.list_slice(buf_state.old_lines, lastline + 1),
    })
        :flatten()
        :totable()
    log.debug("buf.old_lines", buf_state.old_lines)
    ---@type zeta.event.LineEditEvent
    local edit = {
        path = require("zeta.utils").get_buf_rel_path(bufnr),
        a_ctx_lines = vim.list_slice(old_lines, firstline - 2, firstline),
        old_lines = vim.list_slice(old_lines, firstline + 1, lastline),
        value = vim.api.nvim_buf_get_lines(bufnr, firstline, new_lastline, false),
        b_ctx_lines = vim.list_slice(old_lines, lastline + 1, lastline + 4),
        range = { firstline + 1, lastline + 1 },
    }
    log.debug("edit", edit);
    -- push new edit event to event queue
    -- merge it to last edit event if possible
    (function()
        local last_event = state:pop_event()
        if last_event then
            log.debug("find last edit:", last_event)
            assert(last_event.value)
            log.debug("try merging", last_event, "and", edit)
            local merged_edit = merge_line_edits(last_event, edit)
            if merged_edit then
                ---@cast merged_edit zeta.event.LineEditEvent
                merged_edit.path = last_event.path
                merged_edit.old_lines = last_event.old_lines
                -- what if... user "merged" it..?
                -- now I have a edit event that doesn't include any change
                if merged_edit.old_lines == merged_edit.value then
                    log.debug("pop")
                    return
                end
                merged_edit.a_ctx_lines = vim.list_slice(old_lines, merged_edit.range[1] - 3, merged_edit.range[1] - 1)
                merged_edit.b_ctx_lines = vim.list_slice(old_lines, merged_edit.range[2], merged_edit.range[2] + 3)
                state:push_event(merged_edit)
                return
            end
            state:push_event(last_event)
        end
        log.debug("can't merge, push new edit")
        state:push_event(edit)
    end)()
    log.debug(state.events)
    log.debug("user edited a file")
    -- log.debug("diff:", vim.diff(table.concat(old_lines), table.concat(new_lines), { ctxlen = 3 }))
    buf_state.old_lines = new_lines
    require("zeta.common").request_predict_completion()
end

---@param bufnr integer
---@param firstline integer
---@param lastline integer
---@param new_lastline integer
local function on_lines_handler(bufnr, firstline, lastline, new_lastline)
    log.debug("on_lines_handler")
    if state.buffers[bufnr].prediction then
        log.debug("text changed. immediately invalidate previous predicted edtis")
        require("zeta.editor").clear_prediction(bufnr)
    end
    local buf_state = state.buffers[bufnr]
    buf_state.needs_flush = true
    reset_timer(buf_state)
    local debounce = next_debounce(buf_state.debounce, buf_state.last_flush)
    if debounce == 0 or lastline ~= new_lastline then
        handle_changes(bufnr, firstline, lastline, new_lastline, buf_state)
    else
        local timer = assert(uv.new_timer(), "Must be able to create timer")
        buf_state.timer = timer
        timer:start(
            debounce,
            0,
            vim.schedule_wrap(function()
                reset_timer(buf_state)
                handle_changes(bufnr, firstline, lastline, new_lastline, buf_state)
            end)
        )
    end
end

---@param bufnr integer
---@return boolean did_attached
function M.attach(bufnr)
    if state.buffers[bufnr] then
        return false
    end
    state.buffers[bufnr] = {
        debounce = TEXTCHANGE_DEBOUNCE,
        needs_flush = true,
        last_flush = 0,
        timer = nil,
        old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    }
    vim.api.nvim_buf_attach(bufnr, true, {
        on_lines = function(_, buf, _changetick, firstline, lastline, new_lastline)
            return on_lines_handler(buf, firstline, lastline, new_lastline)
        end,
        on_detach = function()
            log.debug("detach")
        end,
        on_reload = function()
            log.debug("reload")
        end,
    })
    return true
end

return M
