-- Gitsigns configuration - minimal staging workflow
return {
  'lewis6991/gitsigns.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  lazy = false,
  config = function()
    -- Setup gitsigns with minimal config
    require('gitsigns').setup({
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '┃' },
        topdelete    = { text = '┃' },
        changedelete = { text = '┃' },
        untracked    = { text = '┃' },
      },
      signcolumn = false,  -- Disable gutter signs
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = {
        follow_files = true
      },
      attach_to_untracked = true,
      current_line_blame = false,
      sign_priority = 10,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },
      diff_opts = {
        internal = true,
        algorithm = 'histogram',
        indent_heuristic = true,
      },
      on_attach = function(bufnr)
        local gs = require('gitsigns')

        local function map(mode, lhs, rhs, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- gzd - Open diff view
        map('n', 'gzd', function()
          gs.diffthis()
          vim.cmd('windo if &diff | set foldlevel=99 | endif')
          -- Jump to first hunk
          pcall(gs.next_hunk)
        end)

        map('n', '<LocalLeader>gzd', function()
          gs.diffthis()
          vim.cmd('windo if &diff | set foldlevel=99 | endif')
          pcall(gs.next_hunk)
        end)

        -- gzs - Stage hunk
        map('n', 'gzs', function()
          gs.stage_hunk()
        end)

        map('n', '<LocalLeader>gzs', function()
          gs.stage_hunk()
        end)

        -- Stage/reset hunks in visual mode
        map('v', 'gzs', function()
          gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')}
        end)

        map('v', 'gzu', function()
          gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')}
        end)

        -- Text object for hunks
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end
    })

    -- Custom highlights to match vgit style
    vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = '#479B36' })
    vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = '#D79921' })
    vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = '#A02A11' })
    vim.api.nvim_set_hl(0, 'GitSignsAddLn', { bg = '#001a00' })
    vim.api.nvim_set_hl(0, 'GitSignsDeleteLn', { bg = '#330011' })
    vim.api.nvim_set_hl(0, 'GitSignsChangeLn', { bg = '#1a1a00' })
  end,
}
