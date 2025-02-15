-- YES I'M TERRIBLE ON NAMING FILES

local log = require("zeta.log")
local uv = vim.uv

local M = {}

-- NOTE: text sync code is heavily inspired (copied) from Neovim's internal
-- LSP textDocument/didChange implementation

local TEXTCHANGE_DEBOUNCE = 150

---@class zeta.BufState
---@field debounce integer
---@field last_flush integer
---@field needs_flush boolean
---@field timer? uv.uv_timer_t
---@field old_lines string[]

local state = {
    ---@type table<integer, zeta.BufState>
    buffers = {},
}

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
    log.debug("bufnr:", bufnr, "fl:", firstline, "ll:", lastline, "nl:", new_lastline)
    local tbl = {
        vim.list_slice(buf_state.old_lines, 1, firstline),
        vim.api.nvim_buf_get_lines(bufnr, firstline, new_lastline, false),
        vim.list_slice(buf_state.old_lines, lastline + 1),
    }
    buf_state.old_lines = vim.iter(tbl):flatten():totable()

    log.debug("new lines:", table.concat(buf_state.old_lines, "\n"))
    -- TODO: implement core feature starting from here
end

---@param bufnr integer
---@param firstline integer
---@param lastline integer
---@param new_lastline integer
local function on_lines_handler(bufnr, firstline, lastline, new_lastline)
    local buf_state = state.buffers[bufnr]
    buf_state.needs_flush = true
    reset_timer(buf_state)
    local debounce = next_debounce(buf_state.debounce, buf_state.last_flush)
    if debounce == 0 then
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
function M.attach(bufnr)
    if state.buffers[bufnr] then
        return
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
    })
end

return M
