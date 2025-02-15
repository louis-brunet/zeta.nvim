-- why I named this file common.lua?

local M = {}

---@class zeta.InputExcerpt
---@field editable_range zeta.LineRange
---@field prompt string
---@field speculated_output? string

---@class zeta.LineRange
---@field [1] integer start line number
---@field [2] integer end line number

---@class zeta.LineEdit
---@field value string[]
---@field range zeta.LineRange

local _MAX_EVENT_TOKENS = 500
local MAX_CONTEXT_TOKENS = 150
local MAX_REWRITE_TOKENS = 350
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

---@return zeta.InputExcerpt
function M.excerpt_for_cursor_position()
    local bufnr = vim.api.nvim_get_current_buf()
    local remaining_edit_tokens = MAX_REWRITE_TOKENS

    local node = assert(vim.treesitter.get_node(), "can't get node at cursor position")
    while true do
        local node_tokens = tokens_for_bytes(node:byte_length())
        if node_tokens <= MAX_REWRITE_TOKENS then
            remaining_edit_tokens = MAX_REWRITE_TOKENS - node_tokens
            break
        end
        local parent = node:parent()
        if not parent then
            break
        end
        node = parent
    end
    local sr, _sc, er, _ec = node:range()
    local eda_lines_start, eda_lines_end = expand_lines(sr + 1, er + 1, remaining_edit_tokens)
    local ctx_lines_start, ctx_lines_end = expand_lines(eda_lines_start, eda_lines_end, MAX_CONTEXT_TOKENS)
    local path = (function()
        local full_path = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
        local cwd = vim.fs.normalize(vim.fn.getcwd())
        return full_path:gsub(vim.pesc(cwd) .. "/", "")
    end)()
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

---@param old string original lines
---@param new string predicted lines
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
                value = vim.list_slice(new_lines, start_b, end_b),
                range = {
                    offset + start_a,
                    offset + end_a,
                },
            }
            table.insert(edits, edit)
            return 1
        end,
    })
    return edits
end

return M
