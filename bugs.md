- [ ] editing the file after sending a request
    - [ ] editing the file before receiving a response
    - [ ] editing the file after receiving a response and computing edits
- [ ] if an edit chunk changes the line count, then the next edits will be placed on the wrong line
  - could possibly be solved with generic solution to previous bug
- [x] when predicted edit is on the first line, error:
   ```
   E5108: Error executing lua: /my/path/to/zeta.nvim/lua/zeta/editor.lua:68: Invalid 'line': out of range
   stack traceback:
           [C]: in function 'nvim_buf_set_extmark'
           /my/path/to/zeta.nvim/lua/zeta/editor.lua:68: in function 'ask_for_edit'
           /my/path/to/zeta.nvim/lua/zeta/editor.lua:134: in function 'ask'
           /my/path/to/zeta.nvim/lua/zeta/editor.lua:152: in function 'preview_prediction'
           /my/path/to/zeta.nvim/lua/zeta/api.lua:13: in function </my/path/to/zeta.nvim/lua/zeta/api.lua:8>
   ```
- [ ] after some time with the plugin active, start getting errors like "too many files open" when
sending requests
- [x] add-only diff: the "predicted edit" and "apply edit" prompts are not shown on the same
line
- [ ] Error when killing (`vim.uv.kill`) a plenary curl job immediately after creating it:

> Error executing callback:
> ....local/share/nvim/lazy/plenary.nvim/lua/plenary/path.lua:747: ENOENT: no such file or directory: /run/user/1000/plenary_curl_41234726.headers
> stack traceback:
>         [C]: in function 'assert'
>         ....local/share/nvim/lazy/plenary.nvim/lua/plenary/path.lua:747: in function 'read'
>         ....local/share/nvim/lazy/plenary.nvim/lua/plenary/path.lua:875: in function 'readlines'
>         ....local/share/nvim/lazy/plenary.nvim/lua/plenary/curl.lua:253: in function 'response'
>         ....local/share/nvim/lazy/plenary.nvim/lua/plenary/curl.lua:313: in function '_user_on_exit'
>         .../.local/share/nvim/lazy/plenary.nvim/lua/plenary/job.lua:241: in function '_shutdown'
>         .../.local/share/nvim/lazy/plenary.nvim/lua/plenary/job.lua:48: in function <.../.local/share/nvim/lazy/plenary.nvim/lua/plenary/job.lua:39>
