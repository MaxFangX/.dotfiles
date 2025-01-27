-- TODO(max): Docs

-- Source existing Vimscript config while I migrate
-- ~/.config/nvim/
local config_dir = vim.fn.stdpath('config')
vim.cmd('source ' .. config_dir .. '/old-init.vim')
