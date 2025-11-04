-- Profile script to measure where time is spent during staging
-- Auto-loaded by vgit config
-- Use :VgitProfileResults to see results, :VgitProfileReset to reset

local times = {}

-- Wrap a function to record execution time
local function time_wrapped(key, fn)
  return function(...)
    local start = vim.loop.hrtime()
    local result = {fn(...)}
    local elapsed = (vim.loop.hrtime() - start) / 1e6 -- Convert to ms
    times[key] = (times[key] or 0) + elapsed
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

-- Profile key vgit functions
time_function("vgit.git.git_stager", "stage_hunk")
time_function("vgit.git.git_buffer_store", "for_each")
time_function("vgit.git.git_buffer_store", "dispatch")
time_method("vgit.git.GitBuffer", "diff")
time_method("vgit.features.buffer.LiveGutter", "fetch")
time_method("vgit.features.screens.DiffScreen", "stage_hunk")

-- Profile git commands (with truncated command names)
local gitcli = require('vgit.git.gitcli')
local original_run = gitcli.run
gitcli.run = function(args)
  local cmd = table.concat(args, " ")
  local key = "gitcli.run: " .. cmd:sub(1, 50)
  return time_wrapped(key, original_run)(args)
end

return {
  show_times = function()
    print("\n=== Profiling Results ===")
    local op_count = vim.tbl_count(times)
    print(string.format("Total operations profiled: %d\n", op_count))

    -- Sort by time (slowest first)
    local sorted = {}
    for k, v in pairs(times) do
      table.insert(sorted, {name = k, time = v})
    end
    table.sort(sorted, function(a, b) return a.time > b.time end)

    for _, item in ipairs(sorted) do
      print(string.format("%.2fms - %s", item.time, item.name))
    end

    print("\n=== Git Buffer Store State ===")
    local git_buffer_store = require('vgit.git.git_buffer_store')
    print(string.format("Tracked buffers: %d", git_buffer_store.size()))

    print("\n=== Autocmd Count ===")
    local autocmds = vim.api.nvim_get_autocmds({ group = "VGitGroup" })
    print(string.format("Total VGitGroup autocmds: %d", #autocmds))

    local user_autocmds = vim.tbl_filter(function(au)
      return au.event == "User"
    end, autocmds)
    print(string.format("User (custom) autocmds: %d", #user_autocmds))
  end,

  reset = function()
    times = {}
    print("Times reset")
  end
}
