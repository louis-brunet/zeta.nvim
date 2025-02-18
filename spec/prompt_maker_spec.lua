---@module 'luassert'

local _testutils = require("spec.testutils").init()

local common = require("zeta.common")

describe("Create excerpt from cursor position", function()
    it("case: long_example.lua", function()
        vim.cmd.edit("spec/samples/long_example.lua")
        vim.api.nvim_win_set_cursor(0, { 35, 23 })
        local excerpt = common.excerpt_for_cursor_position(50, 32)
        assert.same({
            editable_range = { 33, 36 },
            prompt = [=[
```spec/samples/long_example.lua
        if remaining_tokens > 0 and start > 1 then
            start = start - 1
<|editable_region_start|>
            local line_tokens = tokens_for_bytes(#vim.fn.getline(start))
            remaining_tokens = math.max(remaining_tokens - line_tokens, 0)
            expanded = <|user_cursor_is_here|>true
        end
<|editable_region_end|>
        if remaining_tokens > 0 and end_ < vim.fn.line("$") then
```]=],
            speculated_output = [=[
<|editable_region_start|>
            local line_tokens = tokens_for_bytes(#vim.fn.getline(start))
            remaining_tokens = math.max(remaining_tokens - line_tokens, 0)
            expanded = <|user_cursor_is_here|>true
        end
<|editable_region_end|>
]=],
        }, excerpt)
    end)
end)
