-- Plugin Options - telescope.nvim

return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- fzf-native provides fzf's sorting algorithm for better performance
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make"
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              -- Consistent with fzf.vim behavior
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<Esc>"] = actions.close,
            },
          },

          layout_config = {
            horizontal = {
              preview_width = 0.5,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      -- Load fzf extension
      telescope.load_extension("fzf")

      -- Git hunks picker (<Leader>g)
      vim.keymap.set('n', '<Leader>g', function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local make_entry = require("telescope.make_entry")
        local conf = require("telescope.config").values

        local git_hunks = require('git_hunks')
        local hunks = git_hunks.get_all_hunks()

        if #hunks == 0 then
          print('No unstaged changes or untracked files found')
          return
        end

        -- Convert to quickfix format for telescope
        local entries = {}
        for _, hunk in ipairs(hunks) do
          table.insert(entries, {
            filename = hunk.file,
            lnum = hunk.lnum,
            col = 1,
            text = hunk.text,
          })
        end

        -- Use telescope's built-in quickfix entry maker
        pickers.new({}, {
          prompt_title = "Git Hunks",
          finder = finders.new_table({
            results = entries,
            entry_maker = make_entry.gen_from_quickfix({}),
          }),
          sorter = conf.generic_sorter({}),
          previewer = conf.qflist_previewer({}),
        }):find()
      end, { noremap = true, silent = true })
    end,
  },
}
