-- GitHub Copilot configuration
return {
    {
        "github/copilot.vim",
        lazy = false,
        init = function()
            -- Disable tab mapping before plugin loads
            vim.g.copilot_no_tab_map = true
        end,
        config = function()
            -- Use <Ctrl-r> to accept a Copilot suggestion
            vim.keymap.set('i', '<C-r>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false,
                silent = true
            })
        end,
    }
}
