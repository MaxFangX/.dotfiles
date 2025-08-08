-- TODO(max): Docs

-- Source core Vimscript config
-- Core configs which are dependency-free and safe to install on remote VMs
local config_dir = vim.fn.stdpath('config')
vim.cmd('source ' .. config_dir .. '/core.vim')

--- { Plugins
    -- Set up lazy.nvim: lua/config/lazy.lua
    -- TODO(max): Currently not working with fzf
    require("config.lazy")

    -- Note: lazy.nvim automatically executes:
    -- - `filetype plugin indent on`
    -- - `syntax enable`
    -- These can be disabled if needed:
    -- vim.cmd('filetype off')
    -- vim.cmd('syntax off')
--- }

--- { Notes for future switch to native LSP:

    -- Original chat: https://chatgpt.com/c/6892b755-7300-8332-8b8d-c0a9dbf71f36
    --
    -- Refinement: Only use this subset of the suggested repos.
    -- I have vetted all of them and cloned them locally.
    -- - https://github.com/nvim-flutter/flutter-tools.nvim
    -- - https://github.com/neovim/nvim-lspconfig
    -- - https://github.com/hrsh7th/nvim-cmp
    -- - https://github.com/mrcjkb/rustaceanvim
    --   - This replaces simrat39/rust-tools.nvim which is no longer maintained.

--- }
