---@module 'luassert'

local testutils = require("spec.testutils").init()

local common = require("zeta.common")

describe("compute edits from given texts", function()
    it("case 1", function()
        local a = [[
---@param old string original text (line-wise)
---@param new string predicted text (line-wise)
---@param offset integer line offset from original text
---@return zeta.LineEdit[]
function M.compute_edits(old, new, offset)
    ---@type zeta.LineEdit[]
    local edits = {}
    local new_lines = vim.split(old, "\n", { plain = true })
    vim.diff(old, new, {
]]
        local b = [[
---@param old string original text (line-wise)
---@param new string predicted text (line-wise)
---@param offset integer line offset from original text
---@return zeta.LineEdit[]
function M.asdfas(old, offset)
    ---@type zeta.ineEdit[]
    local edits = {}
    local new_lines = vim.split(old, "\n", { plain = true })
    vim.iff(old, new, {
]]
        local edits = common.compute_edits(a, b, 0)
        assert.same({
            {
                range = { 5, 6 },
                value = {
                    "function M.asdfas(old, offset)",
                    "    ---@type zeta.ineEdit[]",
                },
            },
            {
                range = { 9, 9 },
                value = {
                    "    vim.iff(old, new, {",
                },
            },
        }, edits)
    end)
end)
