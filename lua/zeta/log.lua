local M = {}

local LOG_DATE_FORMAT = "%F %H:%M:%S"
local DEFAULT_LOG_PATH = vim.fn.stdpath("log") --[[@as string]]
local LARGE = 1e9

local LOG_LEVEL = vim.log.levels.DEBUG

local logfile, openerr
---@private
---Opens log file. Returns true if file is open, false on error
---@return boolean
local function open_logfile()
    -- Try to open file only once
    if logfile then
        return true
    end
    if openerr then
        return false
    end

    vim.fn.mkdir(DEFAULT_LOG_PATH, "-p")
    logfile, openerr = io.open(M.get_logfile(), "w+")
    if not logfile then
        local err_msg = string.format("Failed to open zeta.nvim log file: %s", openerr)
        vim.notify(err_msg, vim.log.levels.ERROR, { title = "zeta.nvim" })
        return false
    end

    ---@diagnostic disable-next-line: undefined-field
    local log_info = vim.uv.fs_stat(M.get_logfile())
    if log_info and log_info.size > LARGE then
        local warn_msg = string.format(
            "zeta.nvim log is large (%d MB): %s",
            log_info.size / (1000 * 1000),
            M.get_logfile()
        )
        vim.notify(warn_msg, vim.log.levels.WARN, { title = "zeta.nvim" })
    end

    -- Start message for logging
    logfile:write(string.format("[START][%s] zeta.nvim logging initiated\n", os.date(LOG_DATE_FORMAT)))
    return true
end

---Get the zeta.nvim log file path.
---@return string filepath
function M.get_logfile()
    return vim.fs.joinpath(DEFAULT_LOG_PATH, "zeta-nvim.log")
end

---Log to the log file with log level DEBUG.
---For string arguments, logs the string.
---For function arguments, logs the return value. The function is only called if
---the log level is high enough.
---For other argument types, logs the result of vim.inspect() for the argument.
---
---@param ... unknown message
---@return boolean logged
function M.debug(...)
    if LOG_LEVEL == vim.log.levels.OFF or not open_logfile() then
        return false
    end
    local argc = select("#", ...)
    if vim.log.levels.DEBUG < LOG_LEVEL then
        return false
    end
    if argc == 0 then
        return true
    end
    local info = debug.getinfo(2, "Sl")
    local fileinfo = string.format("%s:%s", info.short_src, info.currentline)
    local parts = { "DEBUG", "|", os.date(LOG_DATE_FORMAT), "|", fileinfo, "|" }
    for i = 1, argc do
        local arg = select(i, ...)
        if arg == nil then
            table.insert(parts, "<nil>")
        elseif type(arg) == "string" then
            table.insert(parts, arg)
        elseif type(arg) == "function" then
            local returned = arg()
            local returned_str = type(returned) == "string" and returned or vim.inspect(returned)
            table.insert(parts, returned_str)
        else
            table.insert(parts, vim.inspect(arg))
        end
    end
    logfile:write(table.concat(parts, " "), "\n")
    logfile:flush()
    return true
end

---@param message string log message
---@param level? integer|nil log level, see vim.log.levels
function M.notify(message, level)
    if level == nil then
        level = vim.log.levels.INFO
    end
    vim.notify(message, level, { title = "zeta.nvim" })
end

return M
