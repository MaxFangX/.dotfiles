-- Plugin Options - telescope.nvim

local enable_coc = vim.env.DOTFILES_NVIM_ENABLE_COC == "1"

local dependencies = {
  "nvim-lua/plenary.nvim",
  -- fzf-native provides fzf's sorting algorithm for better performance
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make"
  },
}

if enable_coc then
  -- telescope-coc provides coc.nvim integration
  table.insert(dependencies, "fannheyward/telescope-coc.nvim")
end

return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = dependencies,
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

          -- Default layout config shared by all pickers (document symbols,
          -- git hunks, etc.) unless overridden
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

      if enable_coc then
        telescope.load_extension("coc")

        -- CoC symbol pickers
        local coc_telescope = require("coc_telescope")

        vim.keymap.set("n", "<Leader>s", coc_telescope.document_symbols,
          { noremap = true, silent = true, desc = "document symbols" })

        -- Verbose view: Show all symbols (variables, fields, enum variants,
        -- trait method implementations)
        vim.keymap.set("n", "<Leader>S", function()
          coc_telescope.document_symbols({
            show_variables = true,
            show_fields = true,
            show_enum_members = true,
            filter_trait_method_impls = false,
          })
        end, { noremap = true, silent = true, desc = "document symbols (verbose)" })

        vim.keymap.set("n", "<Leader>w", coc_telescope.workspace_symbols,
          { noremap = true, silent = true, desc = "workspace symbols" })
      end

      -- Git picker helper function
      local function git_picker(files_only)
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local entry_display = require("telescope.pickers.entry_display")

        local git_hunks = require('git_hunks')
        local items = files_only
          and git_hunks.get_files_with_changes()
          or git_hunks.get_all_hunks()

        if #items == 0 then
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
            lnum = item.lnum or 1,
            status = item.text,
          }
        end

        local prompt_title = files_only
          and "Git Files (Unstaged)"
          or "Git Hunks (Unstaged)"

        pickers.new({}, {
          prompt_title = prompt_title,
          finder = finders.new_table({
            results = items,
            entry_maker = entry_maker,
          }),
          sorter = conf.generic_sorter({}),
          previewer = conf.qflist_previewer({}),
        }):find()
      end

      -- Git hunks picker (<Leader>g)
      vim.keymap.set('n', '<Leader>g', function()
        git_picker(false)
      end, { noremap = true, silent = true })

      -- Git files picker (<Leader>G)
      vim.keymap.set('n', '<Leader>G', function()
        git_picker(true)
      end, { noremap = true, silent = true })
    end,
  },
}
