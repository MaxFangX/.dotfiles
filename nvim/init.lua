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
