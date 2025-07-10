-- Theme plugin configurations
return {
    --- { Themes
        -- To switch themes, comment out the active one and uncomment another

        -- Classic ChangeTip theme
        -- {
        --     "sjl/badwolf",
        --     config = function()
        --         vim.cmd("colorscheme badwolf")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'badwolf'
        --         vim.g.airline_theme = 'badwolf'
        --     end,
        -- },

        -- Theme through later college
        -- {
        --     "jacoborus/tender.vim",
        --     config = function()
        --         vim.cmd("colorscheme tender")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'tender'
        --         vim.g.airline_theme = 'tender'
        --     end,
        -- },

        -- Eutykhia theme
        -- More configs at https://github.com/morhetz/gruvbox/wiki/Configuration
        {
            "morhetz/gruvbox",
            lazy = false,
            config = function()
                -- Can be 'soft', 'medium' or 'hard'
                vim.g.gruvbox_contrast_dark = 'hard'
                vim.cmd("colorscheme gruvbox")
                vim.g.lightline = vim.g.lightline or {}
                vim.g.lightline.colorscheme = 'gruvbox'
                vim.g.airline_theme = 'gruvbox'
            end,
        },

        -- Lighter version of Gruvbox
        -- {
        --     "sainnhe/gruvbox-material",
        --     config = function()
        --         vim.cmd("colorscheme gruvbox-material")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'gruvbox-material'
        --         vim.g.airline_theme = 'gruvbox-material'
        --     end,
        -- },

        -- Cold, icy blue theme
        -- {
        --     "cocopon/iceberg.vim",
        --     config = function()
        --         vim.cmd("colorscheme iceberg")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'iceberg'
        --         vim.g.airline_theme = 'iceberg'
        --     end,
        -- },

        -- Crisp dark material theme
        -- {
        --     "kaicataldo/material.vim",
        --     config = function()
        --         -- Use 'ocean' or 'darker'
        --         vim.g.material_theme_style = 'ocean'
        --         vim.cmd("colorscheme material")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'material'
        --         vim.g.airline_theme = 'material'
        --     end,
        -- },

        -- Dark sepia-ish
        -- {
        --     "AlessandroYorba/Alduin",
        --     config = function()
        --         vim.g.alduin_Shout_Dragon_Aspect = 1   -- Almost black background
        --         vim.g.alduin_Shout_Become_Ethereal = 1  -- Black background
        --         vim.cmd("colorscheme alduin")
        --         vim.g.lightline = vim.g.lightline or {}
        --         vim.g.lightline.colorscheme = 'alduin'
        --         vim.g.airline_theme = 'alduin'
        --     end,
        -- },
    --- }
}
