-- Buffer history navigation plugin
return {
    "ton/vim-bufsurf",
    config = function()
        -- This plugin exposes :BufSurfForward and :BufSurfBack
        -- <Plug>(buf-surf-forward) and <Plug>(buf-surf-back) are also
        -- available

        -- Option + QWERTY ]: Go forward one buffer
        vim.keymap.set("n", "'", "<Plug>(buf-surf-forward)",
            { silent = true })

        -- Option + QWERTY [ or side mouse: Go back one buffer
        vim.keymap.set("n", [["]], "<Plug>(buf-surf-back)",
            { silent = true })
        vim.keymap.set("n", "<MiddleMouse>", "<Plug>(buf-surf-back)",
            { silent = true })
        vim.keymap.set("v", "<MiddleMouse>", "<Plug>(buf-surf-back)",
            { silent = true })

        -- Old mappings in case vim-bufsurf doesn't work
        -- vim.keymap.set("n", [["]], "<C-^>", { silent = true })
        -- vim.keymap.set("n", "<MiddleMouse>", "<C-^>", { silent = true })
    end,
}