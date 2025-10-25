-- Visual Git Plugin configuration
local is_macos = vim.loop.os_uname().sysname == 'Darwin'

return {
  -- Use local fork with timer leak fix on macOS, upstream otherwise
  is_macos and '~/dev/nvim/vgit.nvim' or 'tanvirtin/vgit.nvim',
  dir = is_macos and '~/dev/nvim/vgit.nvim' or nil,
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
    local prev_cursor_pos = nil  -- Track cursor position {line, col}

    -- Configuration flags
    local enable_gutter_refresh = false  -- Toggle gutter refresh on exit

    -- Track timers for cleanup to prevent leaks
    local pending_timers = {}
    local cursor_restore_timer = nil

    -- Helper to cancel all pending timers and clear the list
    local function cancel_pending_timers()
      for _, timer in ipairs(pending_timers) do
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
        end
      end
      pending_timers = {}
      -- Don't cancel cursor_restore_timer - that needs to complete
    end

    -- Wrapper around vim.defer_fn that tracks timers for cleanup
    local function defer_fn_tracked(fn, ms)
      local timer = vim.loop.new_timer()
      table.insert(pending_timers, timer)

      timer:start(ms, 0, function()
        vim.schedule(function()
          -- Remove this timer from pending list when it fires
          for i, t in ipairs(pending_timers) do
            if t == timer then
              table.remove(pending_timers, i)
              break
            end
          end

          fn()

          if not timer:is_closing() then
            timer:close()
          end
        end)
      end)
    end

    -- Check if file is untracked
    helpers.is_untracked = function(filepath)
      local relative = vim.fn.fnamemodify(filepath, ':.')
      return vim.fn.system('git ls-files --others --exclude-standard ' ..
        vim.fn.shellescape(relative)):match('%S') ~= nil
    end

    -- Helper to save current window and buffer before opening vgit preview
    helpers.save_window = function()
      prev_window = vim.api.nvim_get_current_win()
      prev_buffer = vim.api.nvim_get_current_buf()
      prev_cursor_pos = vim.api.nvim_win_get_cursor(0)  -- {line, col}
    end

    -- Helper to restore cursor position for untracked files after opening diff
    helpers.restore_cursor_for_untracked = function(saved_pos)
      if cursor_restore_timer and not cursor_restore_timer:is_closing() then
        cursor_restore_timer:stop()
        cursor_restore_timer:close()
      end
      cursor_restore_timer = vim.loop.new_timer()
      cursor_restore_timer:start(200, 0, function()
        vim.schedule(function()
          pcall(vim.api.nvim_win_set_cursor, 0, saved_pos)
          vim.cmd('normal! zz')
          if not cursor_restore_timer:is_closing() then
            cursor_restore_timer:close()
          end
        end)
      end)
    end

    -- Helper to restore previous window and buffer after closing vgit preview
    helpers.restore_window = function()
      -- Cancel cursor restore timer if it's still pending
      if cursor_restore_timer and not cursor_restore_timer:is_closing() then
        cursor_restore_timer:stop()
        cursor_restore_timer:close()
        cursor_restore_timer = nil
      end

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
        local is_untracked = helpers.is_untracked(current_file)

        -- Check if file has unstaged hunks
        local diff_output = vim.fn.systemlist(
          'git diff -U0 ' .. vim.fn.shellescape(current_file))
        local has_hunks = false
        for _, line in ipairs(diff_output) do
          if line:match('^@@') then
            has_hunks = true
            break
          end
        end

        if has_hunks or is_untracked then
          -- File still has hunks or is untracked - restore cursor position
          if prev_cursor_pos then
            pcall(vim.api.nvim_win_set_cursor, 0, prev_cursor_pos)
            vim.cmd('normal! zz')
          end
        else
          -- No hunks left in file - jump to next file with hunks
          pcall(function()
            helpers.jump_to_next_unstaged_hunk()
          end)
        end

        prev_window = nil
        prev_buffer = nil
        prev_cursor_pos = nil

        -- Show count of remaining unstaged and untracked files
        local unstaged_count = #vim.fn.systemlist('git diff --name-only')
        local untracked_count = #vim.fn.systemlist(
          'git ls-files --others --exclude-standard')
        local total_count = unstaged_count + untracked_count

        if total_count > 0 then
          local parts = {}
          if unstaged_count > 0 then
            table.insert(parts, string.format('%d unstaged', unstaged_count))
          end
          if untracked_count > 0 then
            table.insert(parts, string.format('%d untracked', untracked_count))
          end
          print(string.format('%d file%s remaining (%s)',
                            total_count,
                            total_count == 1 and '' or 's',
                            table.concat(parts, ', ')))
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

      -- Get git root to convert relative paths to absolute
      local git_root_output = vim.fn.systemlist(
        'git rev-parse --show-toplevel')
      local git_root = git_root_output[1]
      if not git_root or vim.v.shell_error ~= 0 then
        print('Error: Not in a git repository')
        return
      end

      -- Get all files with unstaged changes and untracked files
      local unstaged_files = vim.fn.systemlist('git diff --name-only')
      local untracked_files = vim.fn.systemlist(
        'git ls-files --others --exclude-standard')

      if #unstaged_files == 0 and #untracked_files == 0 then
        print('No unstaged changes or untracked files found')
        return
      end

      -- Build list of all hunks across all files
      local all_hunks = {}

      -- Add hunks from unstaged files
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
              end_line = end_line,
              is_untracked = false
            })
          end
        end
      end

      -- Add untracked files (entire file is a "hunk")
      for _, file in ipairs(untracked_files) do
        table.insert(all_hunks, {
          file = file,
          absolute_file = vim.fn.fnamemodify(git_root .. '/' .. file, ':p'),
          start_line = 1,
          end_line = 1,
          is_untracked = true
        })
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
          -- Find the next/previous file alphabetically with hunks

          -- Get unique files from all_hunks
          -- (already in git's alphabetical order)
          local files_with_hunks = {}
          local seen_files = {}
          for _, hunk in ipairs(all_hunks) do
            if not seen_files[hunk.file] then
              table.insert(files_with_hunks, hunk.file)
              seen_files[hunk.file] = true
            end
          end

          -- Get current file's relative path for comparison
          local escaped_root = vim.fn.escape(git_root, '/\\')
          local pattern = '^' .. escaped_root .. '/?'
          local current_file_relative = vim.fn.fnamemodify(
            current_file:gsub(pattern, ''), ':.'
          )

          if direction == 'next' then
            -- Find first file alphabetically after current file
            local next_file = nil
            for _, file in ipairs(files_with_hunks) do
              if file > current_file_relative then
                next_file = file
                break
              end
            end

            if next_file then
              -- Jump to first hunk in the next file alphabetically
              for i, hunk in ipairs(all_hunks) do
                if hunk.file == next_file then
                  target_hunk = all_hunks[i]
                  action_description = 'next file'
                  break
                end
              end
            else
              -- No files after current, wrap to first file
              target_hunk = all_hunks[1]
              action_description = 'first file'
            end
          elseif direction == 'prev' then
            -- Find last file alphabetically before current file
            local prev_file = nil
            for i = #files_with_hunks, 1, -1 do
              local file = files_with_hunks[i]
              if file < current_file_relative then
                prev_file = file
                break
              end
            end

            if prev_file then
              -- Jump to last hunk in the previous file alphabetically
              local last_hunk_in_prev_file = nil
              for i = #all_hunks, 1, -1 do
                if all_hunks[i].file == prev_file then
                  last_hunk_in_prev_file = all_hunks[i]
                  target_hunk = last_hunk_in_prev_file
                  action_description = 'previous file'
                  break
                end
              end
            else
              -- No files before current, wrap to last file's last hunk
              target_hunk = all_hunks[#all_hunks]
              action_description = 'last file'
            end
          end
        end
      end

      -- Jump to the target hunk
      if target_hunk.absolute_file ~= absolute_current_file then
        vim.cmd('edit ' .. vim.fn.fnameescape(target_hunk.absolute_file))
      end
      vim.cmd('normal! ' .. target_hunk.start_line .. 'Gzz')

      -- Update quickfix list highlighting if it's open
      local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
      if qf_winid ~= 0 then
        -- Get the current quickfix list (don't refresh)
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
      local file_status = target_hunk.is_untracked and 'untracked file' or 'hunk'
      print(string.format('Jumped to %s %s: %s:%d',
                        action_description, file_status, target_hunk.file,
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
          local is_untracked = helpers.is_untracked(vim.fn.expand('%:p'))
          local saved_pos = vim.api.nvim_win_get_cursor(0)
          helpers.save_window()
          require('vgit').buffer_diff_preview()
          if is_untracked then
            helpers.restore_cursor_for_untracked(saved_pos)
          end
        end,
        ['n <LocalLeader>gd'] = function()
          local is_untracked = helpers.is_untracked(vim.fn.expand('%:p'))
          local saved_pos = vim.api.nvim_win_get_cursor(0)
          helpers.save_window()
          require('vgit').buffer_diff_preview()
          if is_untracked then
            helpers.restore_cursor_for_untracked(saved_pos)
          end
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

    -- Helper function to restore syntax highlighting if lost
    -- This consolidates all syntax restoration logic in one place
    local function restore_syntax_if_needed(bufnr)
      -- Skip during search/command mode to avoid interfering with search
      -- highlights
      local mode = vim.fn.mode()
      if mode:match('[/?]') or mode == 'c' then
        return
      end

      -- Only check normal file buffers
      local buftype = vim.bo[bufnr].buftype
      if buftype ~= '' then
        return
      end

      local filetype = vim.bo[bufnr].filetype
      local syntax = vim.bo[bufnr].syntax
      local filename = vim.api.nvim_buf_get_name(bufnr)

      -- If we have a real file but no filetype, something went wrong
      if filename == '' or vim.fn.filereadable(filename) ~= 1 then
        return
      end

      if filetype == '' then
        -- Re-detect filetype
        vim.cmd('silent! doautocmd BufRead ' ..
                vim.fn.fnameescape(filename))

        -- If still no filetype, try filetype detect
        if vim.bo[bufnr].filetype == '' then
          vim.cmd('silent! filetype detect')
        end
      end

      -- If we have a filetype but no syntax, re-enable syntax
      if vim.bo[bufnr].filetype ~= '' and syntax == '' then
        vim.cmd('silent! syntax enable')
      end
    end

    -- VGIT GUTTER REFRESH WORKAROUND
    -- After staging changes in the diff preview, the gutter doesn't update
    -- immediately due to timing issues with vgit's file watcher. This
    -- workaround forces a refresh when returning from the diff preview.

    -- Track when we're coming from a vgit preview buffer
    local coming_from_vgit = false

    -- Detect when entering vgit preview buffers
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local filetype = vim.bo.filetype
        local buftype = vim.bo.buftype

        -- vgit preview buffers have buftype 'nofile' and empty filetype
        if buftype == 'nofile' and filetype == '' then
          coming_from_vgit = true
          -- Cancel any pending timers from previous preview to avoid races
          cancel_pending_timers()
        end
      end
    })

    -- Only restore syntax when actually returning from vgit, not constantly
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local buftype = vim.bo[bufnr].buftype

        -- Only run when returning to normal buffer from vgit
        if buftype == '' and coming_from_vgit then
          -- Defer to ensure buffer is fully loaded
          defer_fn_tracked(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              restore_syntax_if_needed(bufnr)
            end
          end, 50)
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
          -- Record the cursor position in the diff view
          prev_cursor_pos = vim.api.nvim_win_get_cursor(0)
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

          -- Force gutter refresh with a simplified approach
          if enable_gutter_refresh then
            defer_fn_tracked(function()
              local bufnr = vim.api.nvim_get_current_buf()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end

              -- Clear existing signs to force refresh
              vim.fn.sign_unplace('vgit_signs', { buffer = bufnr })

              -- Toggle gutter to force vgit to re-detect changes
              vim.schedule(function()
                pcall(function()
                  local vgit = require('vgit')
                  vgit.toggle_live_gutter()

                  -- Toggle back after a brief delay
                  defer_fn_tracked(function()
                    pcall(function()
                      vgit.toggle_live_gutter()
                      -- Restore syntax if it was lost during toggle
                      restore_syntax_if_needed(bufnr)
                    end)
                  end, 100)
                end)
              end)
            end, 100)
          end
        end
      end
    })

    -- Set colorcolumn at 80, 100 chars for vgit diff preview windows
    -- Track which windows we've configured to avoid redundant updates
    local colorcolumn_configured = {}

    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = vgit_group,
      pattern = '*',
      callback = function()
        -- Guard against restricted contexts
        if vim.fn.getcmdwintype() ~= '' then
          return
        end
        local bufnr = vim.api.nvim_get_current_buf()
        local winnr = vim.api.nvim_get_current_win()

        -- Early exit if already configured or not a nofile buffer
        if colorcolumn_configured[winnr] or vim.bo[bufnr].buftype ~= 'nofile' then
          return
        end

        -- Check if this is a vgit diff buffer
        local is_vgit_diff = vim.bo[bufnr].modifiable == false
                          and vim.bo[bufnr].buflisted == false
                          and vim.bo[bufnr].bufhidden == 'wipe'
                          and (vim.wo[winnr].cursorbind
                               or vim.wo[winnr].scrollbind)

        if is_vgit_diff then
          colorcolumn_configured[winnr] = true

          -- Detect line number prefix width and set colorcolumn
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
      end
    })

    -- Clean up colorcolumn tracking when windows close
    vim.api.nvim_create_autocmd('WinClosed', {
      group = vgit_group,
      callback = function(args)
        local winnr = tonumber(args.match)
        if winnr then
          colorcolumn_configured[winnr] = nil
        end
      end
    })
  end,
}
