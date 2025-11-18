-- Profile script to measure time spent entering diff staging view
-- Auto-loaded by vgit config
-- Use :VGitEnterViewProfileResult to see results

local stats = {}
local suppression_stats = {
  suppress_calls = 0,
  vgitsync_suppressed = 0,
  vgitsync_fired = 0,
}

-- Wrap a function to record execution time and call count
local function time_wrapped(key, fn)
  return function(...)
    local start = vim.loop.hrtime()
    local result = {fn(...)}
    local elapsed = (vim.loop.hrtime() - start) / 1e6 -- Convert to ms

    if not stats[key] then
      stats[key] = { total_ms = 0, count = 0 }
    end
    stats[key].total_ms = stats[key].total_ms + elapsed
    stats[key].count = stats[key].count + 1

    return unpack(result)
  end
end

local function time_function(module_path, func_name)
  local module = require(module_path)
  local original = module[func_name]
  if not original then return end

  local key = module_path .. "." .. func_name
  module[func_name] = time_wrapped(key, original)
end

local function time_method(class_path, method_name)
  local class = require(class_path)
  local original = class[method_name]
  if not original then return end

  local key = class_path .. ":" .. method_name
  class[method_name] = function(self, ...)
    return time_wrapped(key, function(...)
      return original(self, ...)
    end)(...)
  end
end

-- Profile key vgit functions for entering diff view
time_function("vgit", "buffer_diff_preview")
time_method("vgit.features.screens.DiffScreen", "new")
time_method("vgit.features.screens.DiffScreen", "open")
time_method("vgit.git.GitBuffer", "diff")
time_method("vgit.git.GitBuffer", "hunks")

-- Profile git commands (with truncated command names)
local gitcli = require('vgit.git.gitcli')
local original_run = gitcli.run
gitcli.run = function(args)
  local cmd = table.concat(args, " ")
  local key = "gitcli.run: " .. cmd:sub(1, 50)
  return time_wrapped(key, original_run)(args)
end

-- Track VGitSync suppression behavior
local git_buffer_store = require('vgit.git.git_buffer_store')
local original_suppress = git_buffer_store.suppress_sync_for
git_buffer_store.suppress_sync_for = function(ms)
  suppression_stats.suppress_calls = suppression_stats.suppress_calls + 1
  return original_suppress(ms)
end

return {
  show_times = function()
    print("\n=== Enter View Profiling Results ===")
    local unique_ops = vim.tbl_count(stats)
    local total_calls = 0
    for _, stat in pairs(stats) do
      total_calls = total_calls + stat.count
    end
    print(string.format("Unique operations: %d", unique_ops))
    print(string.format("Total calls: %d\n", total_calls))

    print("=== VGitSync Suppression ===")
    print(string.format("suppress_sync_for() called: %dx", suppression_stats.suppress_calls))
    print(string.format("VGitSync suppressed: %dx", suppression_stats.vgitsync_suppressed))
    print(string.format("VGitSync fired: %dx\n", suppression_stats.vgitsync_fired))

    -- Sort by total time (slowest first)
    local sorted = {}
    for k, v in pairs(stats) do
      table.insert(sorted, {
        name = k,
        total_ms = v.total_ms,
        count = v.count,
        avg_ms = v.total_ms / v.count
      })
    end
    table.sort(sorted, function(a, b) return a.total_ms > b.total_ms end)

    for _, item in ipairs(sorted) do
      if item.count > 1 then
        print(string.format(
          "%.2fms total (%dx, %.2fms avg) - %s",
          item.total_ms,
          item.count,
          item.avg_ms,
          item.name
        ))
      else
        print(string.format("%.2fms - %s", item.total_ms, item.name))
      end
    end
  end,

  reset = function()
    stats = {}
    suppression_stats = {
      suppress_calls = 0,
      vgitsync_suppressed = 0,
      vgitsync_fired = 0,
    }
  end,

  -- Called by git_buffer_store VGitSync handler to track suppression
  track_vgitsync_suppressed = function()
    suppression_stats.vgitsync_suppressed = suppression_stats.vgitsync_suppressed + 1
  end,

  track_vgitsync_fired = function()
    suppression_stats.vgitsync_fired = suppression_stats.vgitsync_fired + 1
  end,
}
