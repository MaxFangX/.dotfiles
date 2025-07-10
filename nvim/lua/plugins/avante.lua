-- AI assistant plugin configuration - avante.nvim
return {
    --- { Dependencies
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    --- }

    --- { Main plugin
        {
            "yetone/avante.nvim",
            branch = "main",
            build = "make",
            dependencies = {
                "stevearc/dressing.nvim",
                "nvim-lua/plenary.nvim",
                "MunifTanjim/nui.nvim",
            },
            config = function()
                -- Load avante modules
                require('avante_lib').load()
                require('avante').setup({
                    -- Add any custom configuration here
                })

                -- Dev recommends a global statusline (`set laststatus=3`) to enable full
                -- view collapsing, but keeping the default since it impacts filename display.
                -- vim.opt.laststatus = 3
            end,
        },
    --- }
}