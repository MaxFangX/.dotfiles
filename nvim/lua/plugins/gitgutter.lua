-- vim-gitgutter configuration for testing alongside vgit
-- Uses 'gz' prefix mappings to avoid conflicts with vgit's 'g' mappings

return {
  'airblade/vim-gitgutter',
  enabled = false,  -- Disabled for now, keeping config for future testing
  lazy = false,
  init = function()
    -- Disable default mappings so we can define our own
    vim.g.gitgutter_map_keys = 0

    -- Set updatetime for faster diff updates (affects all plugins)
    -- vim.opt.updatetime = 100  -- Uncomment if you want faster updates
  end,
  config = function()
    -- Set up 'gz' prefix mappings to mirror vgit functionality
    -- This allows testing vim-gitgutter alongside vgit

    -- (s)tage current hunk
    vim.keymap.set('n', 'gzs', ':GitGutterStageHunk<CR>',
      { desc = 'GitGutter: Stage hunk', silent = true })

    -- (d)iff/staging view - opens vimdiff split for full file staging
    vim.keymap.set('n', 'gzd', ':GitGutterDiffOrig<CR>',
      { desc = 'GitGutter: Open vimdiff staging view', silent = true })

    -- (h)unk preview - same as gzd but matches vgit's gh mapping
    vim.keymap.set('n', 'gzh', ':GitGutterPreviewHunk<CR>',
      { desc = 'GitGutter: Preview hunk', silent = true })

    -- (j)ump to next hunk
    vim.keymap.set('n', 'gzj', ':GitGutterNextHunk<CR>',
      { desc = 'GitGutter: Next hunk', silent = true })

    -- (J)ump to previous hunk
    vim.keymap.set('n', 'gzJ', ':GitGutterPrevHunk<CR>',
      { desc = 'GitGutter: Previous hunk', silent = true })

    -- (q)uickfix list of hunks
    vim.keymap.set('n', 'gzq', ':GitGutterQuickFix | copen<CR>',
      { desc = 'GitGutter: Quickfix hunks', silent = true })

    -- (u)ndo/reset current hunk
    vim.keymap.set('n', 'gzu', ':GitGutterUndoHunk<CR>',
      { desc = 'GitGutter: Undo hunk', silent = true })

    -- Additional useful mappings:

    -- (t)oggle gitgutter on/off
    vim.keymap.set('n', 'gzt', ':GitGutterToggle<CR>',
      { desc = 'GitGutter: Toggle on/off', silent = true })

    -- (b)lame - not available in gitgutter, but keeping for consistency
    -- You could integrate with vim-fugitive here if needed

    -- (D)iff first file - not available in gitgutter
    -- This is a custom vgit feature

    -- Text object for hunks (optional)
    -- This allows you to use 'ic' (inner change) and 'ac' (around change)
    vim.keymap.set('o', 'ih', '<Plug>(GitGutterTextObjectInnerPending)',
      { desc = 'GitGutter: Inner hunk text object' })
    vim.keymap.set('o', 'ah', '<Plug>(GitGutterTextObjectOuterPending)',
      { desc = 'GitGutter: Around hunk text object' })
    vim.keymap.set('x', 'ih', '<Plug>(GitGutterTextObjectInnerVisual)',
      { desc = 'GitGutter: Inner hunk text object' })
    vim.keymap.set('x', 'ah', '<Plug>(GitGutterTextObjectOuterVisual)',
      { desc = 'GitGutter: Around hunk text object' })
  end,
}
