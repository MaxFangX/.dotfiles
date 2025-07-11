-- Visual Git Plugin configuration
return {
  'tanvirtin/vgit.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  -- Load on BufReadPre to catch the initial buffer events
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    -- Helper functions defined in a table for better organization
    local helpers = {}

    -- Refresh gutter after preview closes
    helpers.with_gutter_refresh = function(fn)
      return function()
        fn()
        -- Set up autocmd to refresh gutter when preview closes
        vim.api.nvim_create_autocmd({'BufWinLeave', 'WinClosed'}, {
          pattern = '*',
          once = true,
          callback = function()
            vim.defer_fn(function()
              -- Refresh the current buffer's git status
              local git_buffer_store = require('vgit.git.git_buffer_store')
              local buffer = git_buffer_store.current()
              if buffer then
                buffer:sync()
                buffer:render_signs()
              end
            end, 50)
          end
        })
      end
    end

    -- Generate quickfix list of files with unstaged changes
    helpers.unstaged_hunks_to_quickfix = function()
      local items = {}

      -- Get unstaged files
      local unstaged_files = vim.fn.systemlist('git diff --name-only')

      for _, file in ipairs(unstaged_files) do
        -- Add one entry per file
        table.insert(items, {
          filename = file,
          lnum = 1,
          text = 'Unstaged changes'
        })
      end

      if #items == 0 then
        print('No unstaged changes found')
      else
        vim.fn.setqflist(items, 'r')
        vim.cmd('copen')
        print(string.format('Found %d files with unstaged changes', #items))
      end
    end

    local vgit = require('vgit')
    vgit.setup({
      -- Keymaps for git diff viewing and staging workflow
      keymaps = {
        -- === <Leader> mappings === --

        -- (P)revious hunk
        ['n <Leader>p'] = function() require('vgit').hunk_up() end,
        -- (N)ext hunk
        ['n <Leader>n'] = function() require('vgit').hunk_down() end,

        -- (H)unk preview
        -- ['n <Leader>H'] = helpers.with_gutter_refresh(function()
        --   require('vgit').buffer_hunk_preview()
        -- end),
        -- (D)iff preview of current buffer
        -- ['n <Leader>D'] = helpers.with_gutter_refresh(function()
        --   require('vgit').buffer_diff_preview()
        -- end),
        -- (P)roject diff preview
        -- ['n <Leader>P'] = helpers.with_gutter_refresh(function()
        --   require('vgit').project_diff_preview()
        -- end),

        -- === <LocalLeader> mappings === --
        -- All are namespaced with <LocalLeader>g: (g)it

        -- (h)unk preview
        ['n <LocalLeader>gh'] = helpers.with_gutter_refresh(function()
          require('vgit').buffer_hunk_preview()
        end),
        -- (d)iff preview of current buffer
        ['n <LocalLeader>gd'] = helpers.with_gutter_refresh(function()
          require('vgit').buffer_diff_preview()
        end),
        -- (p)roject diff preview
        ['n <LocalLeader>gp'] = helpers.with_gutter_refresh(function()
          require('vgit').project_diff_preview()
        end),
        -- (q)uickfix list of all unstaged hunks
        ['n <LocalLeader>gq'] = helpers.unstaged_hunks_to_quickfix,

                -- (s)tage current hunk
        ['n <LocalLeader>gs'] = function() require('vgit').buffer_hunk_stage() end,
        -- (S)tage entire file
        ['n <LocalLeader>gS'] = function() require('vgit').buffer_stage() end,

        -- (u)nstage/reset current hunk
        ['n <LocalLeader>gu'] = function() require('vgit').buffer_hunk_reset() end,
        -- (U)nstage entire file
        ['n <LocalLeader>gU'] = function() require('vgit').buffer_unstage() end,

        -- (r)eset current hunk to HEAD
        ['n <LocalLeader>gr'] = function() require('vgit').buffer_hunk_reset() end,
        -- (R)eset entire file to HEAD
        ['n <LocalLeader>gR'] = function() require('vgit').buffer_reset() end,

        -- (b)lame preview for current line
        ['n <LocalLeader>gb'] = helpers.with_gutter_refresh(function()
          require('vgit').buffer_blame_preview()
        end),
        -- (l)og history of current file (like git log)
        ['n <LocalLeader>gl'] = helpers.with_gutter_refresh(function()
          require('vgit').buffer_history_preview()
        end),

        -- e(x)change/toggle between split and unified diff view
        ['n <LocalLeader>gx'] = function() require('vgit').toggle_diff_preference() end,

        -- Toggle live (B)lame annotations
        ['n <LocalLeader>gB'] = function() require('vgit').toggle_live_blame() end,
        -- Toggle live gutter signs
        ['n <LocalLeader>g<C-g>'] = function() require('vgit').toggle_live_gutter() end,
      },

      settings = {
        -- General settings
        git = {
          cmd = 'git', -- Use system git
          fallback_cwd = vim.fn.getcwd(),
          fallback_args = {
            '--no-pager',
            '--literal-pathspecs',
            '-c', 'gc.auto=0',
          },
        },

        -- Live gutter signs for changes
        live_gutter = {
          enabled = true,
          edge_navigation = true, -- Navigate within hunks
        },

        -- Live blame annotations
        live_blame = {
          enabled = false, -- Toggle with <LocalLeader>gB
          format = function(blame, git_config)
            local config_author = git_config['user.name']
            local author = blame.author
            if config_author == author then
              author = 'You'
            end

            if not blame.committed then
              author = 'You'
              return string.format(' %s • Uncommitted changes', author)
            end

            local time = os.difftime(os.time(), blame.author_time) / (60 * 60 * 24)
            local time_str = string.format('%d days ago', math.floor(time))
            if time < 1 then
              time_str = 'today'
            elseif time < 2 then
              time_str = 'yesterday'
            elseif time > 365 then
              time_str = string.format('%d years ago', math.floor(time / 365))
            elseif time > 30 then
              time_str = string.format('%d months ago', math.floor(time / 30))
            end

            local commit_message = blame.commit_message
            local max_commit_message_length = 60
            if #commit_message > max_commit_message_length then
              commit_message = commit_message:sub(1, max_commit_message_length) .. '...'
            end

            return string.format(' %s, %s • %s', author, time_str, commit_message)
          end,
        },

        -- Scene settings
        scene = {
          diff_preference = 'split', -- Prefer split view over unified
          keymaps = {
            quit = 'q'
          }
        },

        -- Diff preview settings
        diff_preview = {
          keymaps = {
            reset = 'r',
            buffer_stage = 'S',
            buffer_unstage = 'U',
            buffer_hunk_stage = 's',
            buffer_hunk_unstage = 'u',
            -- (v)iew: Changed from 't' to avoid DVORAK conflict
            toggle_view = 'v',
            -- Navigate between hunks in diff preview
            -- Doesn't appear to work
            -- previous_hunk = '<Up>',
            -- next_hunk = '<Down>',
          },
        },

        -- Project diff preview settings
        project_diff_preview = {
          keymaps = {
            buffer_stage = 's',      -- (s)tage file
            buffer_unstage = 'u',    -- (u)nstage file
            buffer_hunk_stage = 'gs', -- (g)it hunk (s)tage
            buffer_hunk_unstage = 'gu', -- (g)it hunk (u)nstage
            buffer_reset = 'r',      -- (r)eset file
            stage_all = 'S',         -- (S)tage all
            unstage_all = 'U',       -- (U)nstage all
            reset_all = 'R',         -- (R)eset all
          },
        },

        -- Visual settings inspired by delta configuration
        hls = {
          -- File paths and decorations
          GitTitle = 'Title',
          GitHeader = 'DiffText',
          GitFooter = 'Normal',
          GitBorder = 'LineNr',
          GitLineNr = 'LineNr',
          GitComment = 'Comment',

          -- Signs for changes (inspired by delta colors)
          GitSignsAdd = {
            fg = '#479B36', -- Green from delta config
            bg = nil,
          },
          GitSignsChange = {
            fg = '#D79921', -- Yellow from gruvbox theme
            bg = nil,
          },
          GitSignsDelete = {
            fg = '#A02A11', -- Red from delta config
            bg = nil,
          },

          -- Diff highlighting (inspired by delta's gruvbox-dark theme)
          GitSignsAddLn = {
            bg = '#001a00', -- Dark green background
          },
          GitSignsDeleteLn = {
            bg = '#330011', -- Dark red background
          },
          GitWordAdd = {
            bg = '#003300', -- Dark green from delta config
          },
          GitWordDelete = {
            bg = '#80002a', -- Dark red from delta config
          },
        },

        -- Signs configuration
        signs = {
          priority = 10,
          definitions = {
            GitSignsAdd = {
              texthl = 'GitSignsAdd',
              text = '┃',
            },
            GitSignsDelete = {
              texthl = 'GitSignsDelete',
              text = '┃',
            },
            GitSignsChange = {
              texthl = 'GitSignsChange',
              text = '┃',
            },
          },
        },

        -- Symbols configuration
        symbols = {
          void = ' ', -- Remove dots filler in empty lines
        },
      }
    })
  end,
}
