-- Buffer history navigation plugin
return {
    "ton/vim-bufsurf",
    config = function()
        -- This plugin exposes :BufSurfForward and :BufSurfBack
        -- <Plug>(buf-surf-forward) and <Plug>(buf-surf-back) are also
        -- available

        -- NOTE: Claude seems incapable of writing the curly quotes “ and ‘ used
        -- by the keybindings below - they get corrected to " and '.
        -- Be wary of these being changed accidentally.

        -- Option + QWERTY ]: Go forward one buffer
        vim.keymap.set("n", "‘", "<Plug>(buf-surf-forward)",
            { silent = true })

        -- Option + QWERTY [ or side mouse: Go back one buffer
        vim.keymap.set("n", '“', "<Plug>(buf-surf-back)",
            { silent = true })
        vim.keymap.set("n", "<MiddleMouse>", "<Plug>(buf-surf-back)",
            { silent = true })
        vim.keymap.set("v", "<MiddleMouse>", "<Plug>(buf-surf-back)",
            { silent = true })
    end,
}
