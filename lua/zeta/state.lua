local log = require "zeta.log"
local state = {}

local MAX_EVENT_COUNT = 10
---@class zeta.BufState
---@field debounce integer
---@field last_flush integer
---@field needs_flush boolean
---@field timer? uv.uv_timer_t
---@field old_lines string[]
---@field prediction? zeta.Prediction

---@type table<integer, zeta.BufState>
state.buffers = {}
---@type zeta.event.LineEditEvent[]
state.events = {}
---@type Job[] each request is the result of `require("plenary.curl").post()`
state.pending_requests = {}

function state:push_event(event)
    table.insert(state.events, event)
    while #state.events > MAX_EVENT_COUNT do
        table.remove(state.events, 1)
    end
end

function state:pop_event()
    return table.remove(state.events, #state.events)
end

function state:cancel_pending_requests()
    log.debug("cancel_pending_requests")
    for _, request in ipairs(state.pending_requests) do
        log.debug("cancelling request with PID " .. request.pid)
        if not request.is_shutdown then
            vim.uv.kill(request.pid, 'sigint')
        end
    end
    state.pending_requests = {}
end

---@param request Job
function state:push_pending_request(request)
    table.insert(state.pending_requests, request)
end

---@param request Job
---@return Job|nil
function state:remove_pending_request(request)
    local request_index = -1
    for index, pending_request in ipairs(state.pending_requests) do
        if pending_request == request then
            request_index = index
        end
    end
    if request_index >= 0 then
        -- log.debug("finished request with PID " .. request:pid())
        return table.remove(state.pending_requests, request_index)
    end
    return nil
end

return state
