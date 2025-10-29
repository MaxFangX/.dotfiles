-- Tab-scoped buffers: makes each tab have its own buffer list
-- Commands like :bnext/:bprev only cycle through current tab's buffers
return {
    "tiagovla/scope.nvim",

    config = function()
        require("scope").setup({})

        -- Smart buffer closing that switches to another buffer instead of
        -- closing the tab when closing the last visible buffer
        vim.api.nvim_create_user_command("Bd", function(opts)
            require("scope.core").close_buffer({
                force = opts.bang,
                ask = not opts.bang
            })
        end, {
            bang = true,
            desc = "Smart close buffer (scope.nvim)"
        })

        -- Remap :bd to use scope's smart close
        vim.cmd([[cnoreabbrev bd Bd]])
        vim.cmd([[cnoreabbrev bd! Bd!]])
    end,
}
