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

function state:push_event(event)
    table.insert(state.events, event)
    while #state.events > MAX_EVENT_COUNT do
        table.remove(state.events, 1)
    end
end

function state:pop_event()
    return table.remove(state.events, #state.events)
end

return state
