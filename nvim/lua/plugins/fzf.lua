-- Plugin Options - fzf.vim
-- NOTE: :FZF is still available. See :help FZF for details.
--
-- NOTE: Full list of fzf.vim commands:
-- * :Files [PATH]       Files (runs $FZF_DEFAULT_COMMAND if defined)
-- * :GFiles [OPTS]      Git files (git ls-files)
-- * :GFiles?            Git files (git status)
-- * :Buffers            Open buffers
-- * :Colors             Color schemes
-- * :Ag [PATTERN]       ag search result (ALT-A to select all, ALT-D to
--                       deselect all)
-- * :Rg [PATTERN]       rg search result (ALT-A to select all, ALT-D to
--                       deselect all)
-- * :Lines [QUERY]      Lines in loaded buffers
-- * :BLines [QUERY]     Lines in the current buffer
-- * :Tags [QUERY]       Tags in the project (ctags -R)
-- * :BTags [QUERY]      Tags in the current buffer
-- * :Marks              Marks
-- * :Windows            Windows
-- * :Locate PATTERN     locate command output
-- * :History            v:oldfiles and open buffers
-- * :History:           Command history
-- * :History/           Search history
-- * :Snippets           Snippets (UltiSnips)
-- * :Commits            Git commits (requires fugitive.vim)
-- * :BCommits           Git commits for the current buffer; visual-select
--                       lines to track changes in the range
-- * :Commands           Commands
-- * :Maps               Normal mode mappings
-- * :Helptags           Help tags 1
-- * :Filetypes          File types

return {
  -- fzf binary
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },

  -- fzf.vim
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    config = function()
      -- Initialize configuration dictionary
      vim.g.fzf_vim = {}

      -- Add 'Fzf' prefix to all fzf.vim commands
      -- vim.g.fzf_command_prefix = 'Fzf'

      -- [Buffers] Jump to the existing window if possible
      -- Appears to fix the "not allowed to edit another buffer now" issue
      -- I've been having when trying to open multiple files selected via a
      -- fzf search
      -- https://github.com/junegunn/fzf.vim/issues/569
      vim.g.fzf_vim.buffers_jump = 0

      -- :H to fuzzy search [neo]vim help tags
      vim.cmd("command! H Helptags")

      -- fzf.vim > Fix :GFiles to respect .gitignore when *outside* of a
      -- git repo
      --
      -- Original Config: non-working, replaced by phlip9's config below
      --
      -- <Leader>f, <Leader>g to open file search
      -- nnoremap <Leader>f :GFiles<Enter>
      -- xnoremap <Leader>f <Esc>:GFiles<Enter>
      -- nnoremap <Leader>g :Files<Enter>
      -- xnoremap <Leader>g <Esc>:Files<Enter>
      --
      -- Fixed Config: adapted from phlip9's init.vim
      --
      -- build command!'s and mappings for fzf file searching using some
      -- external file listing command `cmd`. creates two variants:
      -- (1) search files, excluding those in .gitignore files and
      -- (2) search _all_ files

      -- fzf file searching using `fd` or `rg`, preferring `fd` cus it has
      -- nicer colors : p
      if vim.fn.executable("fd") == 1 then
        -- fd's `--color` option emits ANSI color codes; tell fzf to show
        -- them properly.
        vim.g.fzf_files_options = { "--ansi" }

        local fd_command = "fd " ..
          "--type f --hidden --follow --color 'always' " ..
          "--strip-cwd-prefix " ..
          "--exclude '.git/*' --exclude 'target/*' --exclude 'tags' "

        vim.g.phlip9_fzf_files_cmd_ignore = fd_command
        vim.g.phlip9_fzf_files_cmd_noignore = fd_command .. "--no-ignore"
      elseif vim.fn.executable("rg") == 1 then
        -- --color 'never': rg doesn't support meaningful colors when
        --                  listing files, so let's just turn them off.
        local rg_command = "rg " ..
          "--hidden --follow --color 'never' --files " ..
          "--glob '!.git/*' --glob '!target/*' --glob '!tags' "

        vim.g.phlip9_fzf_files_cmd_ignore = rg_command
        vim.g.phlip9_fzf_files_cmd_noignore = rg_command .. "--no-ignore"
      end

      -- Define custom commands

      -- Searching across files, ignoring those in .gitignore.
      -- Unlike stock GFiles, this must work outside git repos (important!).
      vim.cmd([[
        command! -bang -nargs=? -complete=dir GFilesFixed
          \ let $FZF_DEFAULT_COMMAND = g:phlip9_fzf_files_cmd_ignore |
          \ call fzf#vim#files(<q-args>,
          \   fzf#vim#with_preview('right:50%'), <bang>0)
      ]])

      -- Searching across _all_ files (with some basic ignores)
      vim.cmd([[
        command! -bang -nargs=? -complete=dir FilesFixed
          \ let $FZF_DEFAULT_COMMAND = g:phlip9_fzf_files_cmd_noignore |
          \ call fzf#vim#files(<q-args>,
          \   fzf#vim#with_preview('right:50%'), <bang>0)
      ]])

      -- <Leader><Space> to open fulltext search
      -- * Tab to select/deselect and move down
      -- * Shift+Tab to select/deselect and move up
      -- * TODO configure: ALT-A to select all, ALT-D to deselect all
      -- * FIXME: <Enter> <C-t>, <C-x>, <C-v> to open selected files in
      --   current window / tabs / split / vsplit
      -- See :Rg command definition with :command Rg
      -- NOTE: Prefer RgWithHidden below, since :Rg ignores .hidden files.
      -- nnoremap <Leader><Space> :Rg<Enter>
      --
      -- Exactly `:Rg` but with `--hidden` added to the ripgrep invocation
      vim.cmd([[
        command! -bang -nargs=* RgWithHidden
          \ call fzf#vim#grep(
          \   "rg --hidden --no-heading --line-number --column " .
          \   "--smart-case --color=always -- " .
          \   fzf#shellescape(<q-args>),
          \   fzf#vim#with_preview(),
          \   <bang>0
          \ )
      ]])

      -- An instructive example that demonstrates a number of quirks of
      -- rg + fzf.
      --
      -- Ripgrep Fzf Example:
      -- * The output piped into fzf needs to contain:
      --   * The path to the file: 'public/node/src/cli.rs'
      --   * The line number: '14:'
      --   * The column: '17:'
      -- * --no-heading ensures each match contains the filename
      -- * --line-number ensures each match contains the line-number
      -- * --column ensures each match contains the column. --column implies
      --   --line-number but we include it anyway for explicitness.
      -- * --smart-case allows case insensitive search normally,
      --   case-sensitive if any letter typed is uppercase
      -- * --color=always just makes it look nicer
      -- * The `rg` invocation needs to end with a trailing space, errors
      --   otherwise
      -- * The (len(<q-args>) > 0 ? <q-args> : '""') thing prevents the
      --   command from showing only an empty list if it was invoked
      --   without arguments:
      --   https://github.com/junegunn/fzf.vim/issues/419#issuecomment-872147450
      --
      -- (The RgFzfExample command was commented out in the original)

      -- Defines :RgL which allows (non-fuzzy) searching for an exactly
      -- query where only one match is displayed per file, imitating
      -- `rg -l <query>`. Useful for search and replace across a whole
      -- project and populating the quickfix list with a deduplicated list
      -- of all files which contain the exact term.
      --
      -- https://github.com/junegunn/fzf.vim#example-advanced-ripgrep-integration
      --
      -- Implementation Notes:
      -- * Instead of invoking ripgrep once with the initial query and
      --   filtering the output with fzf, ripgrep is restarted every time
      --   the query string is updated. This way, the user can open the fzf
      --   window via a vim mapping and begin typing the query *after* fzf
      --   has been invoked.
      -- * Unfortunately, this means that queries are *non-fuzzy* because we
      --   are no longer sending the entire output of ripgrep into fzf to
      --   filter on.
      -- * If the ripgrep output is missing any of these components, vim
      --   will not be able to open the results from the preview window,
      --   resulting in an abstruse 'Vim(let):E684: list index out of
      --   range: 1' error.
      -- * This is why simply passing -l (--files-with-matches) does not
      --   work; the output contains only the filename, not the line number
      --   and column
      -- * Instead, we pass --max-count=1, which tells ripgrep to only show
      --   1 match per file, which achieves the desired result of
      --   deduplication.
      -- * If in the future it is desired to be able to pass arbitrary args
      --   into ripgrep, remove the shellescape() wrapper and the --
      --   separator.
      --   More info: https://github.com/junegunn/fzf.vim/issues/838
      vim.cmd([[
        function! RipgrepOnePerFile(query, fullscreen)
          let command_fmt = 'rg --hidden --no-heading --line-number ' .
            \ '--column --smart-case --color=always --max-count=1 ' .
            \ '-- %s || true'
          let initial_command = printf(command_fmt, shellescape(a:query))
          let reload_command = printf(command_fmt, '{q}')
          let spec = {'options': ['--disabled', '--query', a:query,
            \ '--bind', 'change:reload:'.reload_command]}
          let spec = fzf#vim#with_preview(spec, 'right', 'ctrl-/')
          call fzf#vim#grep(initial_command, 0, spec, a:fullscreen)
        endfunction

        command! -nargs=* -bang RgL call RipgrepOnePerFile(<q-args>, <bang>0)
      ]])

      -- Key mappings
      local opts = { noremap = true, silent = true }

      -- Map <Leader>f and <Leader>F to the two fns above respectively
      vim.keymap.set("n", "<Leader>f", ":GFilesFixed<CR>", opts)
      vim.keymap.set("x", "<Leader>f", "<Esc>:GFilesFixed<CR>", opts)
      vim.keymap.set("n", "<Leader>F", ":FilesFixed<CR>", opts)
      vim.keymap.set("x", "<Leader>F", "<Esc>:FilesFixed<CR>", opts)

      -- <Leader><Space> - Full text search with hidden files
      vim.keymap.set("n", "<Leader><Space>", ":RgWithHidden<CR>", opts)
      vim.keymap.set("x", "<Leader><Space>",
        "<Esc>:RgWithHidden<CR>", opts)

      -- Use <Leader>l to initiate one-per-file exact search.
      -- Think 'rg -l" to remember <Leader>l
      vim.keymap.set("n", "<Leader>l", ":RgL<CR>", opts)

      -- <Leader>b to open buffer search
      -- Useful after piping rg | vim
      vim.keymap.set("n", "<Leader>b", ":Buffers<CR>", opts)
      vim.keymap.set("x", "<Leader>b", "<Esc>:Buffers<CR>", opts)

      -- Other commands:
      -- * :Colors - Switch to any installed theme
      -- * :Commands - See available commands
      -- * :Maps - Alternative view of nmap
      --
      -- Also consider:
      -- * :Tags - Tags in the project (`ctags -R`)
      -- * :BTags - Tags in the current buffer
      -- * :Marks - Marks in the current buffer

      -- Print an error message
      if vim.fn.executable("fd") == 0 and vim.fn.executable("rg") == 0 then
        vim.keymap.set("n", "<Leader>f",
          ':echoerr "Error: neither `fd` nor `rg` installed"<CR>', opts)
        vim.keymap.set("x", "<Leader>f",
          ':echoerr "Error: neither `fd` nor `rg` installed"<CR>', opts)
        vim.keymap.set("n", "<Leader>F",
          ':echoerr "Error: neither `fd` nor `rg` installed"<CR>', opts)
        vim.keymap.set("x", "<Leader>F",
          ':echoerr "Error: neither `fd` nor `rg` installed"<CR>', opts)
      end
    end,
  },
}
