-- All tpope plugins configuration
return {
  -- vim-sensible: Defaults everyone can agree on
  {
    "tpope/vim-sensible",
    priority = 1000, -- Load this early since it sets sensible defaults
  },

  -- vim-surround: Parentheses, tags, and shit
  {
    "tpope/vim-surround",
    config = function()
      -- Remove mapping since ds is is causing moving left to require two
      -- keystrokes: https://github.com/tpope/vim-surround/blob/master/plugin/surround.vim#L599
      vim.g.surround_no_mappings = '1'

      -- Manually add back key mappings, replacing ds with ks
      vim.keymap.set("n", "ks",     "<Plug>Dsurround")
      vim.keymap.set("n", "cs",     "<Plug>Csurround")
      vim.keymap.set("n", "cS",     "<Plug>CSurround")
      vim.keymap.set("n", "ys",     "<Plug>Ysurround")
      vim.keymap.set("n", "yS",     "<Plug>YSurround")
      vim.keymap.set("n", "yss",    "<Plug>Yssurround")
      vim.keymap.set("n", "ySs",    "<Plug>YSsurround")
      vim.keymap.set("n", "ySS",    "<Plug>YSsurround")
      vim.keymap.set("x", "S",      "<Plug>VSurround")
      vim.keymap.set("x", "gS",     "<Plug>VgSurround")
      vim.keymap.set("i", "<C-S>",  "<Plug>Isurround")
      vim.keymap.set("i", "<C-G>s", "<Plug>Isurround")
      vim.keymap.set("i", "<C-G>S", "<Plug>ISurround")
    end,
  },

  -- Plugin maps are repeatable
  "tpope/vim-repeat",

  -- Arbitrary git with :Git or just :G
  "tpope/vim-fugitive",

  -- Comment / uncomment
  "tpope/vim-commentary",

  -- Readline (emacs) shortcuts in vim
  "tpope/vim-rsi",
}
