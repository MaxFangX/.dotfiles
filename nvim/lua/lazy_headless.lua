-- Headless lazy.nvim operations for `hms` (restore) and `just update nvim`
-- (update). lazy logs every task and exits 0 even when one fails, so
-- callers set LAZY_QUIET (see config/lazy.lua) and `run` reports errored
-- tasks itself, exiting 1 if there were any.
local M = {}

local function run(op)
  local lazy = require("lazy")
  local Config = require("lazy.core.config")

  op(lazy)

  local failed = {}
  for _, plugin in pairs(Config.plugins) do
    for _, task in ipairs(plugin._.tasks or {}) do
      if task:has_errors() then
        table.insert(failed, ("[%s] %s: %s"):format(
          plugin.name, task.name, task:output(vim.log.levels.ERROR)))
      end
    end
  end
  if #failed > 0 then
    io.stderr:write(table.concat(failed, "\n") .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qall")
end

-- Move installed plugins to the lockfile's commits and install missing
-- ones at theirs. `install` only honors the lockfile when asked and skips
-- plugins already installed, so `restore` then moves those. Every
-- operation ends by rewriting the lockfile from the installed state,
-- which would erase the pins `restore` needs, so the seed is saved first
-- and put back in between.
function M.restore()
  run(function(lazy)
    local Lock = require("lazy.manage.lock")
    Lock.load()
    local seed = vim.deepcopy(Lock.lock)

    lazy.install({ wait = true, lockfile = true, show = false })
    Lock.lock = seed
    lazy.restore({ wait = true, show = false })
  end)
end

-- Update every plugin to its latest commit, rewriting the lockfile.
function M.update()
  run(function(lazy)
    lazy.install({ wait = true, show = false })
    lazy.update({ wait = true, show = false })
  end)
end

return M
