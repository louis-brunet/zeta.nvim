local utils = {}

---Get relative path string from given buffer
---returns "untitled" if buffer name is empty
---@param bufnr integer
---@return string path
function utils.get_buf_rel_path(bufnr)
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    if buf_name == "" then
        return "untitled"
    end
    local full_path = vim.fs.normalize(buf_name)
    local cwd = vim.fs.normalize(vim.fn.getcwd())
    local path = full_path:gsub(vim.pesc(cwd) .. "/", "")
    return path
end

return utils
