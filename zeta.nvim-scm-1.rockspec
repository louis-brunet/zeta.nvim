---@diagnostic disable: lowercase-global
local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "zeta.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1, < 5.4",
    "nvim-nio",
    "plenary.nvim",
    "tree-sitter-lua",
    "tree-sitter-rust",
}

test_dependencies = {
    "lua >= 5.1",
    "nlua",
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
