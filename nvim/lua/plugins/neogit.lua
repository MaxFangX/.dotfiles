-- Neogit - Git integration for Neovim
return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",         -- Required
        "sindrets/diffview.nvim",        -- (Optional) Diff integration

        -- Only one of these is needed.
        -- "nvim-telescope/telescope.nvim", -- optional
        "ibhagwan/fzf-lua",              -- optional
        -- "echasnovski/mini.pick",         -- optional
        -- "folke/snacks.nvim",             -- optional
    },
    config = true,
}
