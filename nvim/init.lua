-- TODO(max): Docs

-- Source existing Vimscript config while I migrate
-- ~/.config/nvim/init.lua
local config_dir = vim.fn.stdpath('config')
vim.cmd('source ' .. config_dir .. '/init.vim')
