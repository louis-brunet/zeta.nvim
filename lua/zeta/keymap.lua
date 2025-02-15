local keymap = {}

---@param bufnr integer
function keymap.attach(bufnr)
    vim.keymap.set("n", "<plug>(zeta-accept)", function()
        -- TODO: accept edits in vim.b.zeta_predicted_edits
    end, { buffer = bufnr })
end

return keymap
