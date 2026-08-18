-- Git hunk utilities - reusable for quickfix, telescope, fzf, etc.

local M = {}

-- Get all unstaged hunks across all files
-- Returns: array of { file, lnum, end_lnum, text, is_untracked }
function M.get_all_hunks()
  local items = {}

  -- Get unstaged files and their hunks
  local unstaged_files = vim.fn.systemlist('git diff --name-only')
  for _, file in ipairs(unstaged_files) do
    -- Fetch file diff
    local diff_output = vim.fn.systemlist(
      'git diff -U0 ' .. vim.fn.shellescape(file)
    )

    local hunk_num = 0
    for _, line in ipairs(diff_output) do
      -- Parse unified diff header:
      -- @@ -old_start,old_count +new_start,new_count @@
      local new_start, new_count = line:match('^@@.*%+(%d+),?(%d*)')
      if new_start then
        hunk_num = hunk_num + 1
        local lnum = tonumber(new_start)
        local count = tonumber(new_count) or 1
        table.insert(items, {
          file = file,
          lnum = lnum,
          -- For zero-line hunks (pure deletions), end_lnum equals lnum
          end_lnum = lnum + math.max(0, count - 1),
          text = string.format('Hunk %d: Unstaged changes', hunk_num),
          is_untracked = false,
        })
      end
    end

    -- If no hunks found (shouldn't happen), add file with line 1
    if hunk_num == 0 then
      table.insert(items, {
        file = file,
        lnum = 1,
        end_lnum = 1,
        text = 'Unstaged changes',
        is_untracked = false,
      })
    end
  end

  -- Get untracked files (not in git tree)
  local untracked_files = vim.fn.systemlist(
    'git ls-files --others --exclude-standard'
  )
  for _, file in ipairs(untracked_files) do
    table.insert(items, {
      file = file,
      lnum = 1,
      end_lnum = 1,
      text = 'Untracked file',
      is_untracked = true,
    })
  end

  return items
end

-- Get files with unstaged changes or untracked files
-- Returns: array of { file, text, is_untracked }
function M.get_files_with_changes()
  local items = {}

  -- Get unstaged files
  local unstaged_files = vim.fn.systemlist('git diff --name-only')
  for _, file in ipairs(unstaged_files) do
    table.insert(items, {
      file = file,
      text = 'Unstaged changes',
      is_untracked = false,
    })
  end

  -- Get untracked files (not in git tree)
  local untracked_files = vim.fn.systemlist(
    'git ls-files --others --exclude-standard'
  )
  for _, file in ipairs(untracked_files) do
    table.insert(items, {
      file = file,
      text = 'Untracked file',
      is_untracked = true,
    })
  end

  return items
end

-- Check if a file is untracked
-- Returns: boolean
function M.is_untracked(filepath)
  local relative = vim.fn.fnamemodify(filepath, ':.')
  local ls_files_cmd = 'git ls-files --others --exclude-standard '
                       .. vim.fn.shellescape(relative)
  return vim.fn.system(ls_files_cmd):match('%S') ~= nil
end

-- Check if a file has unstaged hunks or is untracked
-- Returns: boolean
function M.has_hunks(filepath)
  if M.is_untracked(filepath) then
    return true
  end

  -- Check if file has unstaged hunks
  local diff_output = vim.fn.systemlist(
    'git diff -U0 ' .. vim.fn.shellescape(filepath))
  for _, line in ipairs(diff_output) do
    if line:match('^@@') then
      return true
    end
  end

  return false
end

-- Populate quickfix list with unstaged hunks
function M.populate_quickfix(log_status)
  local hunks = M.get_all_hunks()

  if #hunks == 0 then
    -- Close quickfix window if open
    vim.cmd('cclose')
    if log_status then
      print('No unstaged changes or untracked files found')
    end
    return
  end

  -- Convert to quickfix format
  local qf_items = {}
  for _, hunk in ipairs(hunks) do
    table.insert(qf_items, {
      filename = hunk.file,
      lnum = hunk.lnum,
      text = hunk.text,
    })
  end

  vim.fn.setqflist(qf_items, 'r')
  vim.cmd('copen')
  if log_status then
    print(string.format('Found %d unstaged hunks', #hunks))
  end
end

return M
