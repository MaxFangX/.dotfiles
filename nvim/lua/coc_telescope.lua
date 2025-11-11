-- CoC integration with Telescope

local M = {}

-- Configuration for document symbols picker
M.config = {
  -- Symbol type filtering
  show_variables = false,            -- Show variable declarations
  show_fields = false,               -- Show struct/class fields
  show_enum_members = false,         -- Show enum variants/members

  -- Trait-specific filtering (Rust)
  filter_trait_method_impls = true,  -- Hide methods in trait impls

  -- Display options
  indent_kinds = true,               -- Indent kinds by nesting level
}

-- Show document symbols in a Telescope picker
-- @param opts Optional config overrides (merged with M.config)
function M.document_symbols(opts)
  -- Merge opts with default config
  local config = vim.tbl_extend("force", M.config, opts or {})

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local entry_display = require("telescope.pickers.entry_display")
  local make_entry = require("telescope.make_entry")
  local sorters = require("telescope.sorters")
  local conf = require("telescope.config").values

  -- Check if CoC is ready
  if vim.g.coc_service_initialized ~= 1 then
    print("CoC is not ready!")
    return
  end

  -- Cursor stability: Capture current cursor position to determine which
  -- symbol should be initially selected in the picker. This creates a more
  -- natural UX where the picker opens with the cursor on the symbol that
  -- corresponds to your current location in the file, rather than always
  -- defaulting to the first symbol.
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Fetch raw symbols and filetype
  local current_buf = vim.api.nvim_get_current_buf()
  local raw_symbols = vim.fn.CocAction('documentSymbols', current_buf)
  local filetype = vim.bo.filetype

  if not raw_symbols or vim.tbl_isempty(raw_symbols) then
    print("No symbols found")
    return
  end

  -- Helper: Check if symbol is a trait implementation
  local function is_trait_impl(symbol)
    return symbol.kind == "Object"
      and symbol.text
      and symbol.text:match("impl%s+.+%s+for%s+") ~= nil
  end

  -- Build lookup tables for symbol context
  local level_by_line = {}
  local context_by_line = {}

  if raw_symbols and type(raw_symbols) == 'table' then
    local parent_stack = {}

    for _, s in ipairs(raw_symbols) do
      local level = s.level or 0
      level_by_line[s.lnum] = level

      -- Pop parents that are not ancestors
      while #parent_stack > 0 and parent_stack[#parent_stack].level >= level do
        table.remove(parent_stack)
      end

      -- Determine context based on parent
      if #parent_stack > 0 then
        local parent = parent_stack[#parent_stack].symbol
        if parent.kind == "Interface" then
          context_by_line[s.lnum] = "trait_method"
        elseif is_trait_impl(parent) then
          context_by_line[s.lnum] = "trait_method_impl"
        end
      end

      -- Context for impl blocks themselves
      if is_trait_impl(s) then
        context_by_line[s.lnum] = "trait_impl"
      end

      table.insert(parent_stack, { symbol = s, level = level })
    end
  end

  -- Symbol type display mapping
  local type_mapping = {
    EnumMember = "enum variant",
    TypeParameter = "type param",
    Method = "method",
    Function = "fn",
    Variable = "var",
    Constant = "const",
    Module = "mod",
  }

  local function transform_symbol_type(symbol_type, symbol_name, context)
    -- Context-specific transformations (trait-related)
    if context == "trait_impl" then
      return "impl trait"
    elseif context == "trait_method" or context == "trait_method_impl" then
      return "trait method"
    end

    -- Rust-specific: "Interface" -> "trait"
    if filetype == "rust" and symbol_type == "Interface" then
      return "trait"
    end

    -- "Object" -> "impl" (when name starts with "impl")
    if symbol_type == "Object" and symbol_name:match("^impl") then
      return "impl"
    end

    -- Use mapping table or return original type
    return type_mapping[symbol_type] or symbol_type
  end

  -- Custom displayer: kind (type), symbol
  local displayer = entry_display.create({
    separator = " │ ",
    items = {
      { width = 18 },      -- kind/type column
      { remaining = true }, -- symbol name column
    },
  })

  -- Rust keyword prefixes (defined once, not per-display)
  local keyword_map = {
    Variable = "let ",
    Struct = "struct ",
    Enum = "enum ",
    Interface = "trait ",
    Module = "mod ",
  }

  local make_display = function(entry)
    local context = context_by_line[entry.lnum]
    local display_type = transform_symbol_type(
      entry.symbol_type,
      entry.symbol_name,
      context
    ):lower()

    -- Indent based on nesting level (2 spaces per level)
    local level = level_by_line[entry.lnum] or 0
    local indent = string.rep("  ", level)

    -- Apply indent to kind if configured, always indent symbol name
    local indented_type = config.indent_kinds
      and (indent .. display_type)
      or display_type

    -- Rust-specific: Add keyword prefixes to symbol names
    local symbol_name = entry.symbol_name
    if filetype == "rust" then
      local prefix = nil

      -- Check for function-like symbols (functions, methods, trait methods)
      if entry.symbol_type == "Function" or entry.symbol_type == "Method"
         or context == "trait_method" or context == "trait_method_impl" then
        prefix = "fn "
      else
        prefix = keyword_map[entry.symbol_type]
      end

      if prefix then
        symbol_name = prefix .. symbol_name
      end
    end

    return displayer({
      { indented_type, "TelescopeResultsFunction" },
      indent .. symbol_name,
    })
  end

  -- Helper: Fuzzy match prompt against line
  local function fuzzy_match(prompt, line)
    local prompt_idx = 1
    local line_idx = 1
    local prompt_len = #prompt
    local line_len = #line

    while prompt_idx <= prompt_len and line_idx <= line_len do
      if prompt:sub(prompt_idx, prompt_idx) == line:sub(line_idx, line_idx) then
        prompt_idx = prompt_idx + 1
      end
      line_idx = line_idx + 1
    end

    return prompt_idx > prompt_len
  end

  -- Custom sorter: fuzzy filters but preserves document order
  local document_order_sorter = sorters.Sorter:new({
    discard = true,
    scoring_function = function(_, prompt, line)
      if prompt == "" then
        return 1
      end

      local lower_prompt = prompt:lower()
      local lower_line = line:lower()

      if fuzzy_match(lower_prompt, lower_line) then
        return 1  -- All matches get same score (preserves order)
      else
        return -1  -- Filtered out
      end
    end,
  })

  -- Build entries from raw symbols
  local entries = {}
  -- Track which entry should be initially selected based on cursor position.
  -- Starts at 1 (first symbol) and updates as we encounter symbols at or
  -- before the cursor line.
  local default_selection_idx = 1
  local filename = vim.api.nvim_buf_get_name(current_buf)

  -- Pre-build filter checks (filters that don't depend on per-symbol context)
  local filter_variables = not config.show_variables
  local filter_fields = not config.show_fields
  local filter_enum_members = not config.show_enum_members
  local filter_trait_impls = config.filter_trait_method_impls

  for _, s in ipairs(raw_symbols) do
    local symbol_type = s.kind
    local symbol_name = s.text
    local context = context_by_line[s.lnum]

    -- Apply filters
    local should_filter = false
    if (filter_variables and symbol_type == "Variable")
       or (filter_fields and symbol_type == "Field")
       or (filter_enum_members and symbol_type == "EnumMember")
       or (filter_trait_impls and context == "trait_method_impl") then
      should_filter = true
    end

    if not should_filter then
      -- Build ordinal for filtering (preserves document order)
      local ordinal_type =
        transform_symbol_type(symbol_type, symbol_name, context)

      -- Add Rust keyword prefix to ordinal for searchability
      local searchable_name = symbol_name
      if filetype == "rust" then
        local prefix = nil
        if symbol_type == "Function" or symbol_type == "Method"
           or context == "trait_method" or context == "trait_method_impl" then
          prefix = "fn "
        else
          prefix = keyword_map[symbol_type]
        end
        if prefix then
          searchable_name = prefix .. symbol_name
        end
      end

      local ordinal = string.format("%05d %s %s",
        s.lnum, searchable_name, ordinal_type)

      local entry = {
        filename = filename,
        lnum = s.lnum,
        col = s.col,
        symbol_name = symbol_name,
        symbol_type = symbol_type,
        ordinal = ordinal,
      }

      table.insert(entries, entry)

      -- Cursor stability: Update the default selection to this entry if the
      -- symbol is at or before the cursor line. By the end of the loop, this
      -- will point to the last symbol before (or at) the cursor position.
      -- Examples:
      --   Cursor before first symbol -> selects first (index stays 1)
      --   Cursor between symbols -> selects previous symbol
      --   Cursor after last symbol -> selects last symbol
      if s.lnum <= cursor_line then
        default_selection_idx = #entries
      end
    end
  end

  -- Build custom picker with cursor stability.
  -- The default_selection_index parameter tells telescope which entry to
  -- highlight when the picker first opens, creating a stable cursor position
  -- that matches your location in the source file.
  pickers.new({}, {
    prompt_title = "CoC Document Symbols",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return make_entry.set_default_entry_mt({
          value = entry,
          ordinal = entry.ordinal,
          display = make_display,
          filename = entry.filename,
          lnum = entry.lnum,
          col = entry.col,
          symbol_name = entry.symbol_name,
          symbol_type = entry.symbol_type,
        }, {})
      end,
    }),
    sorter = document_order_sorter,
    previewer = conf.qflist_previewer({}),
    sorting_strategy = "ascending",
    default_selection_index = default_selection_idx,
    -- Center the selected entry in the viewport after results load.
    -- This is especially helpful when opening the picker from deep in a file.
    on_complete = {
      function(self)
        vim.schedule(function()
          if not vim.api.nvim_win_is_valid(self.results_win) then
            return
          end

          local selection_row = self:get_selection_row()
          local win_height = vim.api.nvim_win_get_height(self.results_win)
          local buf_line_count =
            vim.api.nvim_buf_line_count(self.results_bufnr)

          -- Calculate topline to center the selection
          local topline = math.max(
            1,
            selection_row + 1 - math.floor(win_height / 2)
          )
          topline = math.min(
            topline,
            math.max(1, buf_line_count - win_height + 1)
          )

          vim.api.nvim_win_call(self.results_win, function()
            vim.fn.winrestview({ topline = topline })
          end)
        end)
      end
    },
  }):find()
end

-- Show workspace symbols in a Telescope picker
function M.workspace_symbols()
  local entry_display = require("telescope.pickers.entry_display")
  local utils = require("telescope.utils")
  local make_entry = require("telescope.make_entry")
  local coc = require("telescope").extensions.coc

  -- Custom displayer: path, kind (type), symbol
  local displayer = entry_display.create({
    separator = " │ ",
    items = {
      { width = 40 },      -- path
      { width = 12 },      -- kind/type
      { remaining = true }, -- symbol
    },
  })

  local make_display = function(entry)
    local display_path = utils.transform_path({}, entry.filename)
    return displayer({
      display_path,
      { entry.symbol_type:lower(), "TelescopeResultsFunction" },
      entry.symbol_name,
    })
  end

  coc.workspace_symbols({
    entry_maker = function(entry)
      local symbol_type, symbol_name = entry.text:match("%[(.+)%]%s+(.*)")
      local ordinal = entry.filename .. " " .. symbol_name
        .. " " .. (symbol_type or "unknown")

      return make_entry.set_default_entry_mt({
        value = entry,
        ordinal = ordinal,
        display = make_display,
        filename = entry.filename,
        lnum = entry.lnum,
        col = entry.col,
        symbol_name = symbol_name,
        symbol_type = symbol_type,
      }, {})
    end
  })
end

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
