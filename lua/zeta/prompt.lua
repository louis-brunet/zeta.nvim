local utils = require("zeta.utils")

local M = {}

---@class zeta.InputExcerpt
---@field editable_range zeta.LineRange
---@field prompt string
---@field speculated_output? string

local CURSOR_MARKER = "<|user_cursor_is_here|>"
local START_OF_FILE_MARKER = "<|start_of_file|>"
local EDITABLE_REGION_START_MARKER = "<|editable_region_start|>"
local EDITABLE_REGION_END_MARKER = "<|editable_region_end|>"

local function tokens_for_bytes(bytes)
    return bytes / 3
end

---@param start integer
---@param end_ integer
---@return string[] lines
local function getlines(start, end_)
    return vim.fn.getline(start, end_) --[[@as string[] ]]
end

---@param start integer
---@param end_ integer
---@param remaining_tokens integer
---@return integer start, integer end_
local function expand_lines(start, end_, remaining_tokens)
    while true do
        local expanded = false
        if remaining_tokens > 0 and start > 1 then
            start = start - 1
            local line_tokens = tokens_for_bytes(#vim.fn.getline(start))
            remaining_tokens = math.max(remaining_tokens - line_tokens, 0)
            expanded = true
        end
        if remaining_tokens > 0 and end_ < vim.fn.line("$") then
            end_ = end_ + 1
            local line_tokens = tokens_for_bytes(#vim.fn.getline(end_))
            remaining_tokens = math.max(remaining_tokens - line_tokens, 0)
            expanded = true
        end
        if not expanded then
            break
        end
    end
    return start, end_
end

---@param start integer
---@param end_ integer
local function format_editable_lines(start, end_)
    local pos = vim.api.nvim_win_get_cursor(0)
    local str = EDITABLE_REGION_START_MARKER .. "\n"
    vim.iter(getlines(start, pos[1] - 1)):map(function(line)
        str = str .. line .. "\n"
    end)
    str = str .. vim.fn.getline(pos[1]):sub(0, pos[2])
    str = str .. CURSOR_MARKER
    str = str .. vim.fn.getline(pos[1]):sub(pos[2] + 1) .. "\n"
    vim.iter(getlines(pos[1] + 1, end_)):map(function(line)
        str = str .. line .. "\n"
    end)
    str = str .. EDITABLE_REGION_END_MARKER .. "\n"
    return str
end

---@param editable_token_limit integer
---@param context_token_limit integer
---@return zeta.InputExcerpt
function M.excerpt_for_cursor_position(editable_token_limit, context_token_limit)
    local bufnr = vim.api.nvim_get_current_buf()
    local remaining_edit_tokens = editable_token_limit

    local node = vim.treesitter.get_node()
    while node do
        local node_tokens = tokens_for_bytes(node:byte_length())
        if node_tokens <= editable_token_limit then
            remaining_edit_tokens = editable_token_limit - node_tokens
            break
        end
        node = node:parent()
    end
    ---@type integer, integer
    local scope_start, scope_end
    if node then
        local sr, _sc, er, _ec = node:range()
        scope_start, scope_end = sr + 1, er + 1
    else
        local pos = vim.api.nvim_win_get_cursor(0)
        scope_start, scope_end = pos[1], pos[1]
    end
    local eda_lines_start, eda_lines_end = expand_lines(scope_start, scope_end, remaining_edit_tokens)
    local ctx_lines_start, ctx_lines_end = expand_lines(eda_lines_start, eda_lines_end, context_token_limit)
    local path = utils.get_buf_rel_path(bufnr)
    local prompt = "```" .. path .. "\n"
    if ctx_lines_start == 1 then
        prompt = prompt .. START_OF_FILE_MARKER .. "\n"
    end
    vim.iter(getlines(ctx_lines_start, eda_lines_start - 1)):map(function(line)
        prompt = prompt .. line .. "\n"
    end)
    local speculated_output = format_editable_lines(eda_lines_start, eda_lines_end)
    prompt = prompt .. speculated_output
    vim.iter(getlines(eda_lines_end + 1, ctx_lines_end)):map(function(line)
        prompt = prompt .. line .. "\n"
    end)
    prompt = prompt .. "```"

    return {
        editable_range = { eda_lines_start, eda_lines_end },
        prompt = prompt,
        speculated_output = speculated_output,
    }
end

---@param ev zeta.event.LineEditEvent
---@return string diff text
local function editevent_to_diff(ev)
    local a_ctx = table.concat(ev.a_ctx_lines, "\n") .. "\n"
    local b_ctx = table.concat(ev.b_ctx_lines, "\n") .. "\n"
    local old_text = a_ctx .. table.concat(ev.old_lines, "\n") .. "\n" .. b_ctx
    local new_text = a_ctx .. table.concat(ev.value, "\n") .. "\n" .. b_ctx
    return vim.diff(old_text, new_text, { ctxlen = 3 }) --[[@as string]]
end

---Generate prompt from recent events
---@param events zeta.event.LineEditEvent[]
---@return string
function M.prompt_for_events(events)
    -- TODO: convert event to prompts
    -- e.g. for textchange event, generate diff from given strings
    return vim.iter(events)
        :rev()
        :map(editevent_to_diff)
        :filter(function(s) return s ~= "" end)
        :join("\n")
end

---Generate prompt from tree-sitter AST
---@param bufnr integer
---@return string
function M.prompt_for_outline(bufnr)
    return "TODO"
end

return M
