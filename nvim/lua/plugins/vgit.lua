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
    local prev_window = nil
    local prev_buffer = nil
    local prev_cursor_line = nil  -- Track cursor position in diff view

    -- Helper to save current window and buffer before opening vgit preview
    helpers.save_window = function()
      prev_window = vim.api.nvim_get_current_win()
      prev_buffer = vim.api.nvim_get_current_buf()
      prev_cursor_line = nil  -- Reset cursor tracking
    end

    -- Helper to restore previous window and buffer after closing vgit preview
    helpers.restore_window = function()
      if prev_window and vim.api.nvim_win_is_valid(prev_window) then
        vim.api.nvim_set_current_win(prev_window)

        -- Choose up to 1 of the following behaviors when quitting staging view:

        -- Option 1: Restore original buffer (uncomment to enable)
        -- if prev_buffer and vim.api.nvim_buf_is_valid(prev_buffer) then
        --   vim.api.nvim_win_set_buf(prev_window, prev_buffer)
        -- end

        -- Option 2: Navigate to next hunk (uncomment to enable)
        -- pcall(function()
        --   require('vgit').hunk_down()
        -- end)

        -- Option 3: Smart behavior based on remaining hunks
        -- (currently active)
        local current_file = vim.fn.expand('%:p')
        local diff_output = vim.fn.systemlist(
          'git diff -U0 ' .. vim.fn.shellescape(current_file))
        local has_hunks = false
        for _, line in ipairs(diff_output) do
          if line:match('^@@') then
            has_hunks = true
            break
          end
        end

        if has_hunks then
          -- File still has hunks - restore cursor position if we have it
          if prev_cursor_line then
            vim.cmd('normal! ' .. prev_cursor_line .. 'Gzz')
          end
        else
          -- No hunks left in file - jump to next file with hunks
          pcall(function()
            helpers.jump_to_next_unstaged_hunk()
          end)
        end

        prev_window = nil
        prev_buffer = nil
        prev_cursor_line = nil

        -- Show count of remaining unstaged files
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

    -- Jump to unstaged hunk with direction (next/prev)
    helpers.jump_to_unstaged_hunk = function(direction)
      -- Validate direction parameter
      if direction ~= 'next' and direction ~= 'prev' then
        print(string.format(
          "Invalid direction '%s'. Must be 'next' or 'prev'", direction))
        return
      end

      -- Get current file and cursor position
      local current_file = vim.fn.expand('%:p')
      local current_line = vim.fn.line('.')

      -- Get all files with unstaged changes
      local unstaged_files = vim.fn.systemlist('git diff --name-only')
      if #unstaged_files == 0 then
        print('No unstaged changes found')
        return
      end

      -- Get git root to convert relative paths to absolute
      local git_root_output = vim.fn.systemlist(
        'git rev-parse --show-toplevel')
      local git_root = git_root_output[1]
      if not git_root or vim.v.shell_error ~= 0 then
        print('Error: Not in a git repository')
        return
      end

      -- Build list of all hunks across all files
      local all_hunks = {}
      for _, file in ipairs(unstaged_files) do
        local diff_output = vim.fn.systemlist(
          'git diff -U0 ' .. vim.fn.shellescape(file)
        )

        for _, line in ipairs(diff_output) do
          -- Parse unified diff header:
          -- @@ -old_start,old_count +new_start,new_count @@
          local new_start, new_count = line:match('^@@.*%+(%d+),?(%d*)')
          if new_start then
            local start_line = tonumber(new_start)
            local count = tonumber(new_count) or 1
            -- For zero-line hunks (pure deletions),
            -- end_line should equal start_line
            local end_line = start_line + math.max(0, count - 1)

            table.insert(all_hunks, {
              file = file,
              -- Store absolute path for consistent comparison
              absolute_file = vim.fn.fnamemodify(
                git_root .. '/' .. file, ':p'
              ),
              start_line = start_line,
              end_line = end_line
            })
          end
        end
      end

      if #all_hunks == 0 then
        print('No hunks found')
        return
      end

      -- Find if we're currently in a hunk
      local current_hunk_index = nil
      local absolute_current_file = vim.fn.fnamemodify(current_file, ':p')

      for i, hunk in ipairs(all_hunks) do
        if hunk.absolute_file == absolute_current_file then
          -- Special case: deletion at beginning of file (start_line = 0)
          -- Consider user "in" this hunk if at line 1
          if hunk.start_line == 0 and current_line == 1 then
            current_hunk_index = i
            break
          -- Normal case: check if line is within hunk range
          elseif current_line >= hunk.start_line and
                 current_line <= hunk.end_line then
            current_hunk_index = i
            break
          end
        end
      end

      -- Determine which hunk to jump to
      local target_hunk
      local action_description

      if current_hunk_index then
        -- We're inside a hunk, jump with wraparound
        if direction == 'next' then
          -- Jump to the next hunk (with wraparound)
          -- Note: Lua arrays are 1-indexed, so (index % count) + 1 ensures
          -- we get 1..n, never 0
          local next_index = (current_hunk_index % #all_hunks) + 1
          target_hunk = all_hunks[next_index]
          action_description = 'next'
        elseif direction == 'prev' then
          -- Jump to the previous hunk (with wraparound)
          local prev_index = current_hunk_index - 1
          if prev_index < 1 then
            prev_index = #all_hunks
          end
          target_hunk = all_hunks[prev_index]
          action_description = 'previous'
        end
      else
        -- Not inside a hunk - check if we're between hunks in
        -- current file

        -- Find all hunks in current file
        local hunks_in_current_file = {}
        for i, hunk in ipairs(all_hunks) do
          if hunk.absolute_file == absolute_current_file then
            table.insert(hunks_in_current_file, i)
          end
        end

        if #hunks_in_current_file > 0 then
          -- We're in a file with hunks but between them
          local found_index = nil

          if direction == 'next' then
            -- Find first hunk after current line
            for _, idx in ipairs(hunks_in_current_file) do
              if all_hunks[idx].start_line > current_line then
                found_index = idx
                break
              end
            end

            if found_index then
              -- Found a hunk after cursor in same file
              target_hunk = all_hunks[found_index]
              action_description = 'next'
            else
              -- After all hunks in file, wrap to next file
              local last_idx = hunks_in_current_file[
                #hunks_in_current_file]
              local next_idx = (last_idx % #all_hunks) + 1
              target_hunk = all_hunks[next_idx]
              action_description = 'next'
            end
          elseif direction == 'prev' then
            -- Find last hunk before current line
            for i = #hunks_in_current_file, 1, -1 do
              local idx = hunks_in_current_file[i]
              if all_hunks[idx].end_line < current_line then
                found_index = idx
                break
              end
            end

            if found_index then
              -- Found a hunk before cursor in same file
              target_hunk = all_hunks[found_index]
              action_description = 'previous'
            else
              -- Before all hunks in file, wrap to previous file
              local first_idx = hunks_in_current_file[1]
              local prev_idx = first_idx - 1
              if prev_idx < 1 then
                prev_idx = #all_hunks
              end
              target_hunk = all_hunks[prev_idx]
              action_description = 'previous'
            end
          end
        else
          -- We're in a file without any hunks
          if direction == 'next' then
            target_hunk = all_hunks[1]
            action_description = 'first'
          elseif direction == 'prev' then
            target_hunk = all_hunks[#all_hunks]
            action_description = 'last'
          end
        end
      end

      -- Jump to the target hunk
      if target_hunk.absolute_file ~= absolute_current_file then
        vim.cmd('edit ' .. vim.fn.fnameescape(target_hunk.absolute_file))
      end
      vim.cmd('normal! ' .. target_hunk.start_line .. 'Gzz')

      -- Update quickfix list if it's open
      local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
      if qf_winid ~= 0 then
        -- Refresh the quickfix list to reflect current state
        helpers.quickfix_unstaged_hunks(false)  -- false = don't log status

        -- Get the updated quickfix list
        local qf_list = vim.fn.getqflist()

        -- Find the matching quickfix entry to highlight
        for i, item in ipairs(qf_list) do
          -- Get the filename from quickfix entry
          -- It might be stored as filename or via bufnr
          local qf_file
          if item.bufnr and item.bufnr > 0 then
            qf_file = vim.fn.fnamemodify(
              vim.fn.bufname(item.bufnr), ':p')
          elseif item.filename then
            qf_file = vim.fn.fnamemodify(item.filename, ':p')
          end

          -- Check if this entry matches our target hunk
          if qf_file and qf_file == target_hunk.absolute_file and
             item.lnum == target_hunk.start_line then
            -- Set the quickfix index to highlight this entry
            vim.fn.setqflist({}, 'r', { idx = i })
            break
          end
        end
      end

      -- Report what we did
      -- Use relative file name for cleaner output
      print(string.format('Jumped to %s hunk: %s:%d',
                        action_description, target_hunk.file,
                        target_hunk.start_line))
    end

    -- Jump to next unstaged hunk (or first if not in a hunk)
    helpers.jump_to_next_unstaged_hunk = function()
      helpers.jump_to_unstaged_hunk('next')
    end

    -- Jump to previous unstaged hunk (or last if not in a hunk)
    helpers.jump_to_prev_unstaged_hunk = function()
      helpers.jump_to_unstaged_hunk('prev')
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
          -- Jump to next unstaged hunk after staging
          pcall(helpers.jump_to_next_unstaged_hunk)
        end,

        -- (g)it (d)iff - Open diff preview of current buffer
        ['n gd'] = function()
          helpers.save_window()
          require('vgit').buffer_diff_preview()
        end,
        ['n <LocalLeader>gd'] = function()
          helpers.save_window()
          require('vgit').buffer_diff_preview()
        end,

        -- (g)it (h)over hunk - Show hunk preview
        ['n gh'] = function()
          helpers.save_window()
          require('vgit').buffer_hunk_preview()
        end,

        -- (g)it (j)ump forward:
        -- - Jump to first unstaged hunk if cursor is not over a hunk.
        -- - Jump to next unstaged hunk (possibly in a different file) if cursor
        --   is on a hunk.
        ['n gj'] = helpers.jump_to_next_unstaged_hunk,
        ['n <LocalLeader>gj'] = helpers.jump_to_next_unstaged_hunk,

        -- (g)it (J)ump backward:
        -- - Jump to last unstaged hunk if cursor is not over a hunk.
        -- - Jump to previous unstaged hunk (possibly in a different file) if
        --   cursor is on a hunk.
        ['n gJ'] = helpers.jump_to_prev_unstaged_hunk,
        ['n <LocalLeader>gJ'] = helpers.jump_to_prev_unstaged_hunk,

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
        -- (g)it (D)iff first - Open diff staging view for *first* unstaged file
        ['n gD'] = helpers.open_first_unstaged_diff,
        ['n <LocalLeader>gD'] = helpers.open_first_unstaged_diff,
        -- (p)roject diff preview
        ['n <LocalLeader>gp'] = function()
          helpers.save_window()
          require('vgit').project_diff_preview()
        end,
        -- (q)uickfix list of unstaged hunks
        ['n gq'] = function()
          local log_status = true
          helpers.quickfix_unstaged_hunks(log_status)
        end,
        ['n <LocalLeader>gq'] = function()
          local log_status = true
          helpers.quickfix_unstaged_hunks(log_status)
        end,

        -- (s)tage current hunk
        ['n <LocalLeader>gs'] = function()
          require('vgit').buffer_hunk_stage()
          -- Jump to next unstaged hunk after staging
          pcall(helpers.jump_to_next_unstaged_hunk)
        end,
        -- (S)tage entire file
        ['n <LocalLeader>gS'] = function()
          require('vgit').buffer_stage()
        end,

        -- (u)nstage/reset current hunk
        ['n gu'] = function()
          require('vgit').buffer_hunk_reset()
        end,
        -- (u)nstage entire file
        ['n gU'] = function()
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

    -- Capture cursor position when moving in diff view
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local winnr = vim.api.nvim_get_current_win()

        -- Check if this is a vgit diff buffer (right side - modified file)
        local is_vgit_diff = vim.bo[bufnr].buftype == 'nofile'
                          and vim.bo[bufnr].modifiable == false
                          and vim.bo[bufnr].buflisted == false
                          and vim.bo[bufnr].bufhidden == 'wipe'
                          and vim.wo[winnr].cursorbind

        if is_vgit_diff then
          -- Record the cursor line in the diff view
          prev_cursor_line = vim.fn.line('.')
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
