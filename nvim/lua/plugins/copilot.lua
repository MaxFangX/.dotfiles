-- GitHub Copilot configuration
return {
    {
        "github/copilot.vim",
        lazy = false,
        config = function()
            -- Use <Ctrl-Tab> to accept a Copilot suggestion
            -- Disable tab mapping since it conflicts with CoC autocompletion
            vim.keymap.set('i', '<C-Tab>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false,
                silent = true
            })
            vim.g.copilot_no_tab_map = true
        end,
    }
}
