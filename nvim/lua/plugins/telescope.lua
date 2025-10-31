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

      -- Git files picker (<Leader>g)
      vim.keymap.set('n', '<Leader>g', function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local entry_display = require("telescope.pickers.entry_display")

        local git_hunks = require('git_hunks')
        local files = git_hunks.get_files_with_changes()

        if #files == 0 then
          print('No unstaged changes or untracked files found')
          return
        end

        -- Custom entry maker to show status first
        local displayer = entry_display.create({
          separator = " │ ",
          items = {
            { width = 16 },  -- Status column
            { remaining = true },  -- Filename column
          },
        })

        local make_display = function(entry)
          return displayer({
            entry.status,
            entry.filename,
          })
        end

        local entry_maker = function(item)
          return {
            value = item,
            display = make_display,
            ordinal = item.text .. " " .. item.file,
            filename = item.file,
            lnum = 1,
            status = item.text,
          }
        end

        pickers.new({}, {
          prompt_title = "Git Files (Unstaged)",
          finder = finders.new_table({
            results = files,
            entry_maker = entry_maker,
          }),
          sorter = conf.generic_sorter({}),
          previewer = conf.qflist_previewer({}),
          layout_config = {
            width = 0.55,
            height = 0.75,
            preview_width = 0.55,
          },
        }):find()
      end, { noremap = true, silent = true })
    end,
  },
}
