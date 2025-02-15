---@diagnostic disable: lowercase-global
local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "zeta.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1",
    "nvim-nio",
    "plenary.nvim",
}

test_dependencies = {
    "nlua",
    "tree-sitter-lua",
    "tree-sitter-rust",
}

source = {
    url = "git://github.com/boltlessengineer/" .. package,
}

build = {
    type = "builtin",
    copy_directories = {
        "plugin",
    }
}
