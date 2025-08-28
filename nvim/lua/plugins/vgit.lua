-- Visual Git Plugin configuration
return {
  'tanvirtin/vgit.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  -- Load immediately to ensure keybindings are available
  lazy = false,
  config = function()
    -- Helper functions defined in a table for better organization
    local helpers = {}

    -- Track the window and buffer we came from before opening vgit preview
    local previous_window = nil
    local previous_buffer = nil

    -- Helper to save current window and buffer before opening vgit preview
    helpers.save_window = function()
      previous_window = vim.api.nvim_get_current_win()
      previous_buffer = vim.api.nvim_get_current_buf()
    end

    -- Helper to restore previous window and buffer after closing vgit preview
    helpers.restore_window = function()
      if previous_window and vim.api.nvim_win_is_valid(previous_window) then
        vim.api.nvim_set_current_win(previous_window)
        -- Also restore the original buffer in that window
        if previous_buffer and vim.api.nvim_buf_is_valid(previous_buffer) then
          vim.api.nvim_win_set_buf(previous_window, previous_buffer)
        end
        previous_window = nil
        previous_buffer = nil

        -- Show count of remaining unstaged files
        vim.defer_fn(function()
          local unstaged_files = vim.fn.systemlist('git diff --name-only')
          local count = #unstaged_files
          if count > 0 then
            print(string.format('%d file%s with unstaged changes remaining',
                              count, count == 1 and '' or 's'))
          else
            print('All files staged!')
          end

          -- Refresh quickfix list if it's open
          local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
          if qf_winid ~= 0 then
            helpers.quickfix_unstaged_hunks(false)  -- don't log status
          end
        end, 100)
      end
    end

    -- Open diff staging view for first unstaged file
    helpers.open_first_unstaged_diff = function()
      -- Get first file with unstaged changes
      local unstaged_files = vim.fn.systemlist('git diff --name-only')
      if #unstaged_files > 0 then
        -- Save window BEFORE opening the file
        helpers.save_window()
        local first_file = unstaged_files[1]
        -- Open the file
        vim.cmd('edit ' .. vim.fn.fnameescape(first_file))
        -- Open diff preview
        require('vgit').buffer_diff_preview()
      else
        print('No unstaged changes found')
      end
    end

    -- Jump to first unstaged diff in any file
    helpers.jump_to_first_unstaged = function()
      -- Get first file with unstaged changes
      local unstaged_files = vim.fn.systemlist('git diff --name-only')
      if #unstaged_files == 0 then
        print('No unstaged changes found')
        return
      end

      local first_file = unstaged_files[1]

      -- Get the first hunk's line number from git diff
      local diff_output = vim.fn.systemlist(
        'git diff -U0 ' .. vim.fn.shellescape(first_file)
      )

      local line_num = 1
      for _, line in ipairs(diff_output) do
        -- Parse unified diff header: @@ -l,s +l,s @@
        local new_line = line:match('^@@.*%+(%d+)')
        if new_line then
          line_num = tonumber(new_line)
          break
        end
      end

      -- Open file and jump to line
      vim.cmd('edit ' .. vim.fn.fnameescape(first_file))
      vim.cmd('normal! ' .. line_num .. 'Gzz')
      print(string.format('Jumped to %s:%d', first_file, line_num))
    end

    -- Generate quickfix list with individual hunks for unstaged changes
    helpers.quickfix_unstaged_hunks = function(log_status)
      local items = {}

      -- Get unstaged files and their hunks
      local unstaged_files = vim.fn.systemlist('git diff --name-only')
      for _, file in ipairs(unstaged_files) do
        -- Get hunks for this file
        local diff_output = vim.fn.systemlist(
          'git diff -U0 ' .. vim.fn.shellescape(file)
        )

        local hunk_num = 0
        for _, line in ipairs(diff_output) do
          -- Parse unified diff header: @@ -l,s +l,s @@
          local new_line = line:match('^@@.*%+(%d+)')
          if new_line then
            hunk_num = hunk_num + 1
            table.insert(items, {
              filename = file,
              lnum = tonumber(new_line),
              text = string.format('Hunk %d: Unstaged changes', hunk_num)
            })
          end
        end

        -- If no hunks found (shouldn't happen), add file with line 1
        if hunk_num == 0 then
          table.insert(items, {
            filename = file,
            lnum = 1,
            text = 'Unstaged changes'
          })
        end
      end

      -- Get untracked files (not in git tree)
      local untracked_files = vim.fn.systemlist(
        'git ls-files --others --exclude-standard'
      )
      for _, file in ipairs(untracked_files) do
        table.insert(items, {
          filename = file,
          lnum = 1,
          text = 'Untracked file'
        })
      end

      if #items == 0 then
        -- Close quickfix window if open
        vim.cmd('cclose')
        if log_status then
          print('No unstaged changes or untracked files found')
        end
      else
        vim.fn.setqflist(items, 'r')
        vim.cmd('copen')
        if log_status then
          print(string.format('Found %d unstaged hunks', #items))
        end
      end
    end

    local vgit = require('vgit')
    vgit.setup({
      -- Keymaps for git diff viewing and staging workflow
      keymaps = {
        -- === Global (non-namespaced) mappings === --

        -- Navigate between hunks with <Leader> Up/Down or Shift + up/down
        -- These work everywhere including in diff preview
        ['n <Leader><Up>'] = function() require('vgit').hunk_up() end,
        ['n <Leader><Down>'] = function() require('vgit').hunk_down() end,
        ['n <S-Up>'] = function() require('vgit').hunk_up() end,
        ['n <S-Down>'] = function() require('vgit').hunk_down() end,

        -- (s)tage current hunk and go to next (shorter binding)
        ['n gs'] = function()
          require('vgit').buffer_hunk_stage()
          -- Go to next hunk after staging
          require('vgit').hunk_down()
        end,

        -- (g)it (d)iff - Open diff staging view for first unstaged file
        -- Reverts back to previous window / buffer on quit
        ['n gd'] = helpers.open_first_unstaged_diff,
        ['n <LocalLeader>gd'] = helpers.open_first_unstaged_diff,

        -- (g)it (j)ump - Jump to first unstaged diff in any file
        ['n gj'] = helpers.jump_to_first_unstaged,
        ['n <LocalLeader>gj'] = helpers.jump_to_first_unstaged,

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

        -- (H)over git hunk
        ['n <Leader>H'] = function()
          helpers.save_window()
          require('vgit').buffer_hunk_preview()
        end,
        -- (d)iff preview of current buffer
        -- NOTE: Disable as we have <LocalLeader>gd to open first unstaged file
        -- ['n <LocalLeader>gd'] = function()
        --   helpers.save_window()
        --   require('vgit').buffer_diff_preview()
        -- end,
        -- (p)roject diff preview
        ['n <LocalLeader>gp'] = function()
          helpers.save_window()
          require('vgit').project_diff_preview()
        end,
        -- (q)uickfix list of unstaged hunks
        ['n <LocalLeader>gq'] = function()
          local log_status = true
          helpers.quickfix_unstaged_hunks(log_status)
        end,

        -- (s)tage current hunk
        ['n <LocalLeader>gs'] = function()
          require('vgit').buffer_hunk_stage()
        end,
        -- (S)tage entire file
        ['n <LocalLeader>gS'] = function()
          require('vgit').buffer_stage()
        end,

        -- (u)nstage/reset current hunk
        ['n <LocalLeader>gu'] = function()
          require('vgit').buffer_hunk_reset()
        end,
        -- (U)nstage entire file
        ['n <LocalLeader>gU'] = function()
          require('vgit').buffer_unstage()
        end,

        -- (r)eset current hunk to HEAD
        ['n <LocalLeader>gr'] = function()
          require('vgit').buffer_hunk_reset()
        end,
        -- (R)eset entire file to HEAD
        ['n <LocalLeader>gR'] = function()
          require('vgit').buffer_reset()
        end,

        -- (b)lame preview for current line
        ['n <LocalLeader>gb'] = function()
          require('vgit').buffer_blame_preview()
        end,
        -- (l)og history of current file (like git log)
        ['n <LocalLeader>gl'] = function()
          require('vgit').buffer_history_preview()
        end,

        -- e(x)change/toggle between split and unified diff view
        ['n <LocalLeader>gx'] = function()
          require('vgit').toggle_diff_preference()
        end,

        -- Toggle live (B)lame annotations
        ['n <LocalLeader>gB'] = function()
          require('vgit').toggle_live_blame()
        end,
        -- Toggle live gutter signs
        ['n <LocalLeader>g<C-g>'] = function()
          require('vgit').toggle_live_gutter()
        end,
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
          edge_navigation = false, -- Jump between hunks, not edges
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

            local time = os.difftime(os.time(), blame.author_time)
                        / (60 * 60 * 24)
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
              commit_message = commit_message:sub(1, max_commit_message_length)
                              .. '...'
            end

            return string.format(' %s, %s • %s', author, time_str,
                               commit_message)
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
            -- Note: These don't work as scene-specific keymaps
            -- Use global <S-Up>/<S-Down> instead
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

    -- Create augroup for vgit autocmds
    local vgit_group = vim.api.nvim_create_augroup('VgitConfig',
                                                     { clear = true })

    -- Auto-jump to first hunk when opening file from quickfix
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        -- Check if we came from quickfix window
        local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
        local prev_wininfo = vim.fn.getwininfo(prev_win)[1]

        if prev_wininfo and prev_wininfo.quickfix == 1 then
          -- Small delay to ensure vgit has processed the file
          vim.defer_fn(function()
            pcall(function()
              require('vgit').hunk_down()
            end)
          end, 100)
        end
      end
    })

    -- VGIT GUTTER REFRESH WORKAROUND
    -- After staging changes in the diff preview, the gutter doesn't update
    -- immediately due to timing issues with vgit's file watcher. This
    -- workaround forces a refresh when returning from the diff preview.

    -- Track when we're coming from a vgit preview buffer
    local coming_from_vgit = false

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local filetype = vim.bo.filetype
        local buftype = vim.bo.buftype

        -- vgit preview buffers have buftype 'nofile' and empty filetype
        if buftype == 'nofile' and filetype == '' then
          coming_from_vgit = true
        end
      end
    })

    -- Restore window when closing vgit preview with 'q'
    vim.api.nvim_create_autocmd('BufWipeout', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local buftype = vim.bo.buftype
        -- Check if this is a vgit preview buffer being closed
        if buftype == 'nofile' and coming_from_vgit then
          vim.schedule(function()
            helpers.restore_window()
          end)
        end
      end
    })

    -- Force gutter refresh when returning from vgit preview
    vim.api.nvim_create_autocmd({'WinEnter', 'BufEnter'}, {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local buftype = vim.bo.buftype

        -- Check if we're returning to a normal buffer from vgit
        if buftype == '' and coming_from_vgit then
          coming_from_vgit = false

          -- Restore previous window position
          helpers.restore_window()

          -- Force refresh after a small delay
          vim.defer_fn(function()
            local bufnr = vim.api.nvim_get_current_buf()

            -- Clear existing signs to force refresh
            vim.fn.sign_unplace('vgit_signs', { buffer = bufnr })

            -- Use vim.schedule to avoid coroutine issues
            vim.schedule(function()
              pcall(function()
                local vgit = require('vgit')
                -- Toggle gutter to force refresh
                vgit.toggle_live_gutter()
                vim.defer_fn(function()
                  vgit.toggle_live_gutter()
                end, 50)
              end)
            end)
          end, 100)
        end
      end
    })

    -- Set colorcolumn at 80, 100 chars for vgit diff preview windows
    vim.api.nvim_create_autocmd({'BufWinEnter', 'FileType'}, {
      group = vgit_group,
      pattern = '*',
      callback = function()
        -- Guard against restricted contexts
        if vim.fn.getcmdwintype() ~= '' then
          return
        end
        local bufnr = vim.api.nvim_get_current_buf()
        local winnr = vim.api.nvim_get_current_win()

        -- Check if this is a vgit diff buffer
        local is_vgit_diff = vim.bo[bufnr].buftype == 'nofile'
                          and vim.bo[bufnr].modifiable == false
                          and vim.bo[bufnr].buflisted == false
                          and vim.bo[bufnr].bufhidden == 'wipe'
                          and (vim.wo[winnr].cursorbind
                               or vim.wo[winnr].scrollbind)

        if is_vgit_diff then
          -- Detect line number prefix width and set colorcolumn
          local function set_colorcolumn()
            local lines = vim.api.nvim_buf_get_lines(
              bufnr, 0, math.min(10, vim.api.nvim_buf_line_count(bufnr)), false
            )

            -- Find line number prefix width
            local offset = 0
            for _, line in ipairs(lines) do
              local prefix = line:match("^(%s*%d+%s)")
              if prefix then
                offset = #prefix
                break
              end
            end

            -- Apply offset to standard column positions
            local col80 = 80 + offset
            local col100 = 100 + offset
            vim.wo[winnr].colorcolumn = col80 .. ',' .. col100
          end

          -- Set immediately and after a delay to ensure it sticks
          set_colorcolumn()
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(winnr) then
              set_colorcolumn()
            end
          end, 100)
        end
      end
    })
  end,
}
