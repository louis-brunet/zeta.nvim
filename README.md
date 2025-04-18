# [WIP] zeta.nvim

Neovim's implementation of [Zed]'s [edit prediction] feature.

## Installation

### rocks.nvim

    ```
    :Rocks install zeta.nvim
    ```

### lazy.nvim

```lua
---@type LazySpec
return {
    'boltlessengineer/zeta.nvim',

    -- TODO: add dependencies
    dependencies = {},

    ---@type zeta.Opts
    opts = {},

    -- config = function(_self, opts)
    --     local zeta = require("zeta")
    --     local zeta_autocmd = require("zeta.autocmd")
    --     local zeta_api = require("zeta.api")
    --
    --     zeta.setup(opts)
    --     zeta_autocmd.setup()
    --
    --     vim.keymap.set("n",
    --         "gy",
    --         zeta_api.accept,
    --         { desc = "zeta: accept" }
    --     )
    -- end,
}

```

## Usage

`gy` to accept predicted edits,
cycle through edits and explictly confirm those.

[Zed]: https://zed.dev
[edit prediction]: https://zed.dev/edit-prediction
