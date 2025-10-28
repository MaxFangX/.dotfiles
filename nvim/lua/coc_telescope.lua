-- CoC integration with Telescope (diagnostics picker)

local M = {}

-- Show all CoC diagnostics in a Telescope picker
function M.diagnostics()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local conf = require("telescope.config").values

  -- Check if CoC is ready
  if vim.g.coc_service_initialized ~= 1 then
    print("CoC is not ready yet")
    return
  end

  -- Get diagnostics from CoC
  local ok, diagnostics = pcall(vim.fn.CocAction, 'diagnosticList')
  if not ok then
    print("Failed to get diagnostics from CoC: " .. tostring(diagnostics))
    return
  end

  if vim.tbl_isempty(diagnostics) then
    print("No diagnostics found")
    return
  end

  -- CoC returns severity as strings: "Error", "Warning", "Information", "Hint"
  -- Map to vim.diagnostic.severity constants (uppercase)
  local severity_map = {
    Error = "ERROR",
    Warning = "WARN",
    Information = "INFO",
    Hint = "HINT",
  }

  -- Convert CoC diagnostics to telescope diagnostic format
  local entries = {}
  for _, item in ipairs(diagnostics) do
    local severity_type = severity_map[item.severity] or "ERROR"

    table.insert(entries, {
      bufnr = item.bufnr or vim.fn.bufnr(item.file, false),
      filename = item.file,
      lnum = item.lnum,
      col = item.col,
      text = vim.trim(item.message:gsub("\n", "")),
      type = severity_type,
    })
  end

  -- Use telescope's built-in diagnostic entry maker
  pickers.new({}, {
    prompt_title = "CoC Diagnostics",
    finder = finders.new_table({
      results = entries,
      entry_maker = make_entry.gen_from_diagnostics({}),
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.qflist_previewer({}),
  }):find()
end

return M
