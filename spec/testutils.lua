local utils = {}

function utils.init()
    vim.env.SENSE_NVIM_PLUGIN_DIR = vim.env.SENSE_NVIM_PLUGIN_DIR or vim.fn.getcwd()
    vim.opt.runtimepath:append(assert(vim.env.SENSE_NVIM_PLUGIN_DIR))
    vim.cmd("runtime! ftplugin.vim")
    vim.cmd("runtime! ftdetect/*.{vim,lua}")
    vim.cmd("runtime! filetype.lua")
    vim.cmd("runtime! plugin/**/*.{vim,lua}")
    return utils
end

return utils
