""" { Notes

    " Config Docs: See http://vimdoc.sourceforge.net/htmldoc/options.html
    "
    " For multi-byte character support (CJK support, for example):
    " set fileencodings=ucs-bom,utf-8,cp936,big5,euc-jp,euc-kr,gb18030,latin1
    "
    " Auto Command Groups:
    "
    " All autocmds should be wrapped in a group prefixed with autocmd! to
    " prevent setting duplicate autocmds each time init.vim is resourced.
    "
    " Example: 
    " augroup my_autocmd_group
    "     autocmd!
    "     autocmd FileType python       :iabbrev <buffer> iff if:<left>
    "     autocmd FileType javascript   :iabbrev <buffer> iff if()<left>
    " augroup END
    "
    " More info: https://learnvimscriptthehardway.stevelosh.com/chapters/14.html
    "
    " Map Comments:
    "
    " Vim comments don't work after :map statements.
    "
    " More info: https://learnvimscriptthehardway.stevelosh.com/chapters/03.html
    "
    " Identifying Existing Mappings:
    "
    " Existing mappings can be checked for with e.g. :verbose imap <Tab>
    "
    " Operator Pending Mappings:
    "
    " A good way to keep the multiple ways of creating operator-pending mappings
    " straight is to remember the following two rules:
    "
    " - If your operator-pending mapping ends with some text visually selected,
    "   Vim will operate on that text.
    " - Otherwise, Vim will operate on the text between the original cursor
    "   position and the new position.
    "
    " More info: https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
    "
    " Abbreviations:
    "
    " Cannot contain "|", as learned from experience. However, they *can* contain:
    " - "#"
    " - "<", ">"
    "
    " See the rust abbreviations for more examples.
    "
    " Identifying Vim Names:
    "
    " e.g. for a mouse button
    " - Unmap <C-k> :iunmap <C-k>
    " - Confirme the unmapping using :imap <C-k>
    " - Enter insert mode, type <C-k>, then press the mouse button.
    "   The full vim name (e.g. <MiddleMouse>) will appear.
"""

""" { Core VIM config
    " Core configs which are dependency-free and safe to install on remote VMs.
    source ~/.config/nvim/core.vim
""" }

""" { 'Learn Vimscript the Hard Way' exercises

    " Echoing messages: Display friendly cat when opening vim
    echo "Welcome back! >^.^<"

    " Most of these have been moved to `core.vim`
""" }

" # --- HELPER FUNCTIONS --- #

""" { Consume the space after an abbreviation
    " TODO Fix
    func Eatchar(pat)
      let c = nr2char(getchar(0))
      return (c =~ a:pat) ? '' : c
    endfunc
""" }

" # --- PLUGINS --- #

""" { Plugin Management - vim-plug
    " Notes:
    " - Try to use vim-plug only; I have a comparison between Vim plugin
    "   managers in my [[Vim]] Obsidian note containing the rationale.
    " - It also doesn't require any of that git submodules crap
    " - Git repositories can be referred to via Plug `username/reponame` or
    "   directly with e.g. Plug 'https://github.com/username/reponame.git'
    " - See [[vim-plug]] for one line install command
    call plug#begin()
        Plug 'tpope/vim-sensible'       " 'Defaults everyone can agree on'
        Plug 'tpope/vim-surround'       " Parentheses, tags, and shit
        Plug 'tpope/vim-repeat'         " Plugin maps are repeatable
        Plug 'tpope/vim-fugitive'       " Arbitrary git with :Git or just :G
        Plug 'tpope/vim-commentary'     " Comment / uncomment
        Plug 'tpope/vim-rsi'            " Readline (emacs) shortcuts in vim
        Plug 'jiangmiao/auto-pairs'     " Insert / delete ' '' [ { in pairs
        Plug 'ton/vim-bufsurf'          " Buffer history per window

        """ Search
        Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " Adds :FZF
        Plug 'junegunn/fzf.vim'         " Adds the rest of the commands

        """ Code completion, LSP, etc
        Plug 'neoclide/coc.nvim', {'branch': 'release'}

        """ Javascript: syntax highlighting and indentation
        Plug 'othree/html5.vim'
        Plug 'pangloss/vim-javascript'
        Plug 'evanleck/vim-svelte', {'branch': 'main'}

        """ Rust - simrat39/rust-tools.nvim
        " Common LSP configs
        " Plug 'neovim/nvim-lspconfig'
        " Plug 'simrat39/rust-tools.nvim'
        " Optional dependencies
        " Plug 'nvim-lua/popup.nvim'
        " Plug 'nvim-lua/plenary.nvim'
        " Plug 'nvim-telescope/telescope.nvim'
        " Debugging (needs plenary from above as well)
        " Plug 'mfussenegger/nvim-dap'

        """ AI - avante.nvim
        " Deps
        Plug 'stevearc/dressing.nvim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'MunifTanjim/nui.nvim'
        " Library
        Plug 'yetone/avante.nvim', { 'branch': 'main', 'do': 'make' }

        """ Nix
        " Nix support, including syntax highlighting
        Plug 'LnL7/vim-nix'

        """ UI
        " Plug 'preservim/nerdtree'         " File system explorer
        Plug 'itchyny/lightline.vim'      " Clean and minimal bottom bar
        " Plug 'vim-airline/vim-airline'  " Bottom bar, too much info IMO
        " Plug 'skywind3000/vim-quickui'  " Cuz we ain't gon remember all that

        """ Themes
        Plug 'sjl/badwolf'              " Classic ChangeTip theme
        Plug 'jacoborus/tender.vim'     " Theme through later college
        Plug 'morhetz/gruvbox'          " Eutykhia theme
        Plug 'sainnhe/gruvbox-material' " Lighter version of Gruvbox
        Plug 'cocopon/iceberg.vim'      " Cold, icy blue theme
        Plug 'kaicataldo/material.vim'  " Crisp dark material theme
        Plug 'AlessandroYorba/Alduin'   " Dark sepia-ish
    call plug#end() " Note that this call automagically executes:
                    " - `filetype plugin indent on`
                    " - `syntax enable`
                    " This can be disabled immediately after if needed.

    " Commands:
    " - `PlugInstall [name ...] [#threads]`: Install plugins
    " - `PlugUpdate [name ...] [#threads]`: Install or update plugins
    " - `PlugClean[!]`: Remove unlisted plugins (bang version will clean without prompt)
    " - `PlugUpgrade`: Upgrade vim-plug itself
    " - `PlugStatus`: Check the status of plugins
    " - `PlugDiff`: Examine changes from the previous update and the pending changes
    " - `PlugSnapshot[!] [output path]`: Generate script for restoring the current snapshot of the plugins
""" }

" # --- PLUGIN OPTIONS --- #

""" { vim-surround

    " Remove mapping since ds is is causing moving left to require two keystrokes
    " https://github.com/tpope/vim-surround/blob/master/plugin/surround.vim#L599
    let g:surround_no_mappings = '1'

    " Manually add back key mappings, replacing ds with ks
    nnoremap ks     <Plug>Dsurround
    nnoremap cs     <Plug>Csurround
    nnoremap cS     <Plug>CSurround
    nnoremap ys     <Plug>Ysurround
    nnoremap yS     <Plug>YSurround
    nnoremap yss    <Plug>Yssurround
    nnoremap ySs    <Plug>YSsurround
    nnoremap ySS    <Plug>YSsurround
    xnoremap S      <Plug>VSurround
    xnoremap gS     <Plug>VgSurround
    inoremap <C-S>  <Plug>Isurround
    inoremap <C-G>s <Plug>Isurround
    inoremap <C-G>S <Plug>ISurround
""" }

""" { vim-bufsurf
    " This plugin exposes :BufSurfForward and :BufSurfBack
    " <Plug>(buf-surf-forward) and <Plug>(buf-surf-back) are also available

    " Option + QWERTY ]: Go forward one buffer
    nnoremap <silent> ‘ <Plug>(buf-surf-forward)

    " Option + QWERTY [ or side mouse: Go back one buffer
    nnoremap <silent> “ <Plug>(buf-surf-back)
    nnoremap <silent> <MiddleMouse> <Plug>(buf-surf-back)
    vnoremap <silent> <MiddleMouse> <Plug>(buf-surf-back)

    " Old mappings in case vim-bufsurf doesn't work
    " nnoremap <silent> “ <C-^>
    " nnoremap <silent> <MiddleMouse> <C-^>
""" }

" NOTE: Currently disabled since I don't really use it
" """ { NERDTree
"     " Toggle show NERDTree with Option+8
"     nnoremap • :NERDTreeToggle<Enter>

"     " No existing mapping h
"     " Undo existing mapping t
"     let NERDTreeMapOpenInTab='<Nul>'
"     " No existing mapping v
"     " Undo existing mapping s
"     let NERDTreeMapOpenVSplit='<Nul>'
"     " Undo existing mapping T
"     let NERDTreeMapOpenInTabSilent='<Nul>'

"     " Set my own mappings
"     let NERDTreeMenuDown='h'      " Navigation
"     let NERDTreeMenuUp='t'        " Navigation
"     let NERDTreeMapOpenVSplit='v' " vsplit
"     let NERDTreeMapOpenSplit='s'  " split
"     " let NERDTreeMenuOpenInTabSilent='T' " can't get tab to work
"     " let NERDTreeMenuOpenInTab='T'       " can't get tab to work

"     augroup _
"         autocmd!
"         " Start NERDTree if Vim is started with 0 file arguments or >=2 file args,
"         " move the cursor to the other window if so
"         " autocmd VimEnter * if argc() == 0 || argc() >= 2 | NERDTree | endif
"         " autocmd VimEnter * if argc() == 0 || argc() >= 2 | wincmd p | endif

"         " Open the existing NERDTree on each new tab.
"         autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

"         " If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
"         autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
"             \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

"         " Exit Vim if NERDTree is the only window remaining in the only tab.
"         autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

"         " Close the tab if NERDTree is the only window remaining in it.
"         autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
"     augroup END
" """ }

""" { Plugin Options - lightline.vim

    " Main configuration - see `:help lightline` for the default config.
    " - use relativepath (default: %f) instead of filename (default: %t)
    " - relativepath overflows into the right side (%<)
    " - fileformat and fileencoding are empty in narrow windows (<80 chars)
    " - inactive windows still show left components, but nothing on the right
    " - colorscheme is set via lightline.colorscheme in a different section
    let g:lightline = {
      \ 'active': {
      \     'left': [
      \         [ 'mode', 'paste' ],
      \         [ 'readonly', 'relativepath', 'modified' ]
      \     ],
      \     'right': [
      \         [ 'lineinfo' ],
      \         [ 'percent' ],
      \         [ 'fileformat', 'fileencoding', 'filetype' ]
      \     ]
      \ },
      \ 'inactive': {
      \     'left': [
      \         [ 'mode', 'paste' ],
      \         [ 'readonly', 'relativepath', 'modified' ]
      \     ],
      \     'right': [ ]
      \ },
      \ 'tabline': {
      \     'left': [ [ 'tabs' ] ],
      \     'right': [ [ 'close' ] ]
      \ },
      \ 'component': {
      \   'relativepath': '%f%<'
      \ },
      \ 'component_function': {
      \   'fileformat': 'LightlineFileformat',
      \   'filetype': 'LightlineFiletype',
      \ },
    \ }

    " No file format and encoding information on narrow windows
    function! LightlineFileformat()
        return winwidth(0) >= 80 ? &fileformat : ''
    endfunction
    function! LightlineFiletype()
        return winwidth(0) >= 80 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
    endfunction
""" }

""" { Plugin Options - fzf.vim
    " NOTE: :FZF is still available. See :help FZF for details.

    " NOTE: Full list of fzf.vim commands:
    " - :Files [PATH]	Files (runs $FZF_DEFAULT_COMMAND if defined)
    " - :GFiles [OPTS]	Git files (git ls-files)
    " - :GFiles?	Git files (git status)
    " - :Buffers	Open buffers
    " - :Colors	Color schemes
    " - :Ag [PATTERN]	ag search result (ALT-A to select all, ALT-D to deselect all)
    " - :Rg [PATTERN]	rg search result (ALT-A to select all, ALT-D to deselect all)
    " - :Lines [QUERY]	Lines in loaded buffers
    " - :BLines [QUERY]	Lines in the current buffer
    " - :Tags [QUERY]	Tags in the project (ctags -R)
    " - :BTags [QUERY]	Tags in the current buffer
    " - :Marks	Marks
    " - :Windows	Windows
    " - :Locate PATTERN	locate command output
    " - :History	v:oldfiles and open buffers
    " - :History:	Command history
    " - :History/	Search history
    " - :Snippets	Snippets (UltiSnips)
    " - :Commits	Git commits (requires fugitive.vim)
    " - :BCommits	Git commits for the current buffer; visual-select lines to track changes in the range
    " - :Commands	Commands
    " - :Maps	Normal mode mappings
    " - :Helptags	Help tags 1
    " - :Filetypes	File types

    " Initialize configuration dictionary
    let g:fzf_vim = {}

    " Add 'Fzf' prefix to all fzf.vim commands
    " let g:fzf_command_prefix = 'Fzf'

    " [Buffers] Jump to the existing window if possible
    " Appears to fix the "not allowed to edit another buffer now" issue I've
    " been having when trying to open multiple files selected via a fzf search
    " https://github.com/junegunn/fzf.vim/issues/569
    let g:fzf_vim.buffers_jump = 0

    " :H to fuzzy search [neo]vim help tags
    command H Helptags

    " <Leader><Space> to open fulltext search
    " - Tab to select/deselect and move down
    " - Shift+Tab to select/deselect and move up
    " - TODO configure: ALT-A to select all, ALT-D to deselect all
    " - FIXME: <Enter> <C-t>, <C-x>, <C-v> to open selected files in
    "   current window / tabs / split / vsplit
    " See :Rg command definition with :command Rg
    " NOTE: Prefer RgWithHidden below, since :Rg ignores .hidden files.
    " nnoremap <Leader><Space> :Rg<Enter>

    " Exactly `:Rg` but with `--hidden` added to the ripgrep invocation
    command! -bang -nargs=* RgWithHidden
        \ call fzf#vim#grep(
        \     "rg --hidden --no-heading --line-number --column --smart-case --color=always -- ".fzf#shellescape(<q-args>),
        \     fzf#vim#with_preview(),
        \     <bang>0
        \ )
    nnoremap <Leader><Space> :RgWithHidden<Enter>

    " An instructive example that demonstrates a number of quirks of rg + fzf.
    "
    " Ripgrep Fzf Example:
    " - The output piped into fzf needs to contain:
    "   - The path to the file: 'public/node/src/cli.rs'
    "   - The line number: '14:'
    "   - The column: '17:'
    " - --no-heading ensures each match contains the filename
    " - --line-number ensures each match contains the line-number
    " - --column ensures each match contains the column. --column implies
    "   --line-number but we include it anyway for explicitness.
    " - --smart-case allows case insensitive search normally, case-sensitive if
    "   any letter typed is uppercase
    " - --color=always just makes it look nicer
    " - The `rg` invocation needs to end with a trailing space, errors otherwise
    " - The (len(<q-args>) > 0 ? <q-args> : '""') thing prevents the command
    "   from showing only an empty list if it was invoked without arguments:
    "   https://github.com/junegunn/fzf.vim/issues/419#issuecomment-872147450
    command! -bang -nargs=* RgFzfExample
        \ call fzf#vim#grep(
        \     'rg --no-heading --line-number --column --smart-case --color=always ' 
        \     . (len(<q-args>) > 0 ? <q-args> : '""'), 1,
        \     fzf#vim#with_preview(),
        \     <bang>0
        \ )

    " Defines :RgL which allows (non-fuzzy) searching for an exactly query where
    " only one match is displayed per file, imitating `rg -l <query>`. Useful
    " for search and replace across a whole project and populating the quickfix
    " list with a deduplicated list of all files which contain the exact term.
    "
    " https://github.com/junegunn/fzf.vim#example-advanced-ripgrep-integration
    "
    " Implementation Notes:
    " - Instead of invoking ripgrep once with the initial query and filtering
    "   the output with fzf, ripgrep is restarted every time the query string is
    "   updated. This way, the user can open the fzf window via a vim
    "   mapping and begin typing the query *after* fzf has been invoked.
    " - Unfortunately, this means that queries are *non-fuzzy* because we are no
    "   longer sending the entire output of ripgrep into fzf to filter on.
    " - If the ripgrep output is missing any of these components, vim will not
    "   be able to open the results from the preview window, resulting in an
    "   abstruse 'Vim(let):E684: list index out of range: 1' error.
    " - This is why simply passing -l (--files-with-matches) does not work; the
    "   output contains only the filename, not the line number and column
    " - Instead, we pass --max-count=1, which tells ripgrep to only show 1 match
    "   per file, which achieves the desired result of deduplication.
    " - If in the future it is desired to be able to pass arbitrary args into
    "   ripgrep, remove the shellescape() wrapper and the -- separator.
    "   More info: https://github.com/junegunn/fzf.vim/issues/838
    function! RipgrepOnePerFile(query, fullscreen)
        let command_fmt = 'rg --hidden --no-heading --line-number --column --smart-case --color=always --max-count=1 -- %s || true'
        let initial_command = printf(command_fmt, shellescape(a:query))
        let reload_command = printf(command_fmt, '{q}')
        let spec = {'options': ['--disabled', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
        let spec = fzf#vim#with_preview(spec, 'right', 'ctrl-/')
        call fzf#vim#grep(initial_command, 0, spec, a:fullscreen)
    endfunction
    command! -nargs=* -bang RgL call RipgrepOnePerFile(<q-args>, <bang>0)

    " Use <Leader>l to initiate one-per-file exact search.
    " Think 'rg -l" to remember <Leader>l
    nnoremap <Leader>l :RgL<Enter>

    " <Leader>b to open buffer search
    " Useful after piping rg | vim
    nnoremap <Leader>b :Buffers<Enter>
    xnoremap <Leader>b <Esc>:Buffers<Enter>

    " Other commands:
    " - :Colors - Switch to any installed theme
    " - :Commands - See available commands
    " - :Maps - Alternative view of nmap

    " Also consider:
    " - :Tags - Tags in the project (`ctags -R`)
    " - :BTags - Tags in the current buffer
    " - :Marks - Marks in the current buffer
""" }

""" { fzf.vim > Fix :GFiles to respect .gitignore when *outside* of a git repo

    " Original Config: non-working, replaced by phlip9's config below

    " <Leader>f, <Leader>g to open file search
    " nnoremap <Leader>f :GFiles<Enter>
    " xnoremap <Leader>f <Esc>:GFiles<Enter>
    " nnoremap <Leader>g :Files<Enter>
    " xnoremap <Leader>g <Esc>:Files<Enter>

    " Fixed Config: adapted from phlip9's init.vim

    " build command!'s and mappings for fzf file searching using some external
    " file listing command `cmd`. creates two variants: (1) search files,
    " excluding those in .gitignore files and (2) search _all_ files
    function! s:SetFzfMappings(cmd, no_ignore_opt)
        " command! seems to evaluate lazily, so we need to pre-render these
        let g:phlip9_fzf_files_cmd_ignore = a:cmd
        let g:phlip9_fzf_files_cmd_noignore = a:cmd . ' ' . a:no_ignore_opt

        " Searching across files, ignoring those in .gitignore.
        " Unlike stock GFiles, this must work outside git repos (important!).
        command! -bang -nargs=? -complete=dir GFilesFixed
                    \ let $FZF_DEFAULT_COMMAND = g:phlip9_fzf_files_cmd_ignore |
                    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview('right:50%'), <bang>0)

        " Searching across _all_ files (with some basic ignores)
        command! -bang -nargs=? -complete=dir FilesFixed
                    \ let $FZF_DEFAULT_COMMAND = g:phlip9_fzf_files_cmd_noignore |
                    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview('right:50%'), <bang>0)

        " Map <Leader>f and <Leader>g to the two fns above respectively
        nnoremap <Leader>f :GFilesFixed<Enter>
        xnoremap <Leader>f <Esc>:GFilesFixed<Enter>
        nnoremap <Leader>g :FilesFixed<Enter>
        xnoremap <Leader>g <Esc>:FilesFixed<Enter>
    endfunction

    " fzf file searching using `fd` or `rg`, preferring `fd` cus it has nicer colors : p
    if executable('fd')
        " fd's `--color` option emits ANSI color codes; tell fzf to show them
        " properly.
        let g:fzf_files_options = ['--ansi']
        let fd_command = 'fd ' .
                    \ '--type f --hidden --follow --color "always" --strip-cwd-prefix ' .
                    \ '--exclude ".git/*" --exclude "target/*" --exclude "tags" '
        call s:SetFzfMappings(fd_command, '--no-ignore')
    elseif executable('rg')
        " --color 'never': rg doesn't support meaningful colors when listing
        "                  files, so let's just turn them off.
        let rg_command = 'rg ' .
                    \ '--hidden --follow --color "never" --files ' .
                    \ '--glob "!.git/*" --glob "!target/*" --glob "!tags" '
        call s:SetFzfMappings(rg_command, '--no-ignore')
    else
        " Print an error message
        nnoremap <Leader>f :echoerr "Error: neither `fd` nor `rg` installed"<CR>
        xnoremap <Leader>f :echoerr "Error: neither `fd` nor `rg` installed"<CR>
        nnoremap <Leader>g :echoerr "Error: neither `fd` nor `rg` installed"<CR>
        xnoremap <Leader>g :echoerr "Error: neither `fd` nor `rg` installed"<CR>
    endif
""" }

""" { Plugin Options - coc.nvim
    " NOTE: Use :CocConfig to open the coc.nvim config file.

    " CoC extensions
    let g:coc_global_extensions = [
        \   'coc-flutter',
        \   'coc-json',
        \   'coc-rust-analyzer',
        \   'coc-tsserver',
        \ ]

    " TODO(max): Integrate snippets: `:help coc-snippets`

    """ { Main keybindings
        " List of all CoC actions: `:help coc-actions`

        " Hover
        nnoremap <silent> <Leader>h     :call CocActionAsync('doHover')<CR>
        " <Leader>d or double click: Go to (d)efinition of this item
        nnoremap <silent> <Leader>d     :call CocActionAsync('jumpDefinition')<CR>
        nnoremap <silent> <2-LeftMouse> :call CocActionAsync('jumpDefinition')<CR>
        " Go to the definition of the (t)ype of this item
        nnoremap <silent> <Leader>t :call CocActionAsync('jumpTypeDefinition')<CR>
        " Go to (r)e(f)erences of this item (includes the definition)
        nnoremap <silent> <Leader>r     :call CocActionAsync('jumpReferences')<CR>
        " Go to (u)sages of this item (excludes the definition)
        nnoremap <silent> <Leader>u     :call CocActionAsync('jumpUsed')<CR>
        " Go to (i)mplementation of this item
        nnoremap <silent> <Leader>i     :call CocActionAsync('jumpImplementation')<CR>

        " Structural (r)e(n)ame of this item
        nnoremap <silent> <LocalLeader>rn :call CocActionAsync('rename')<CR>
        " Open a (r)e(f)actor window for this item
        nnoremap <silent> <LocalLeader>rf :call CocActionAsync('refactor')<CR>
        " Toggle inlay hints
        nnoremap <silent> <LocalLeader>i :CocCommand document.toggleInlayHint<Enter>

        " Code actions: `:help coc-code-actions`
        "
        " NOTE: Some sources say that we should not use `noremap` for <Plug>
        " mappings, as plugins themselves may rely upon recursive mappings. This
        " seems pretty dumb, since few if any users would know this, and using
        " recursive mappings within plugin code creates footguns that users are
        " likely to forget. So I'm ignoring this unless something breaks.
        " https://github.com/autozimu/LanguageClient-neovim#quick-start
        "
        " Do code action to quickfi(x) the current line, if any.
        nnoremap <silent> <LocalLeader>x <Plug>(coc-fix-current)
        " View code actions at (c)ursor.
        " - This usually works for auto-importing the item under the cursor.
        nnoremap <silent> <LocalLeader>c <Plug>(coc-codeaction-cursor)
        " View code actions at current (l)ine.
        nnoremap <silent> <LocalLeader>l <Plug>(coc-codeaction-line)
        " View code actions of current (f)ile.
        nnoremap <silent> <LocalLeader>f <Plug>(coc-codeaction)
        " View code action of current file (s)ource.
        nnoremap <silent> <LocalLeader>s <Plug>(coc-codeaction-source)
        " View code action to (r)efactor at the cursor position.
        nnoremap <silent> <LocalLeader>r <Plug>(coc-codeaction-refactor)

        " Visual mode code actions:
        " View code actions for the (s)elected range.
        vnoremap <silent> <LocalLeader>s <Plug>(coc-codeaction-selected)
        " View code actions to (r)efactor the selected range
        vnoremap <silent> <LocalLeader>r <Plug>(coc-codeaction-refactor-selected)

        " rust-analyzer commands
        " See full list at https://github.com/fannheyward/coc-rust-analyzer?tab=readme-ov-file#commands
        " or type :CocCommand and tab through rust-analyzer.<command>
        "
        " Run cargo (c)heck
        nnoremap <silent> <Leader>c     :CocCommand rust-analyzer.runFlycheck<CR>
        " nnoremap <silent> <Leader>xxx :CocCommand rust-analyzer.cancelFlycheck<CR>
        " nnoremap <silent> <Leader>xxx :CocCommand rust-analyzer.reload<CR>
    """ }

    """ { General configuration
        " Adapted from the coc.nvim example config:
        " https://github.com/neoclide/coc.nvim#example-vim-configuration

        " Some servers have issues with backup files, see #649
        set nobackup
        set nowritebackup

        " Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
        " delays and poor user experience.
        set updatetime=300

        " Always show the signcolumn, otherwise it would shift the text each
        " time diagnostics appear/become resolved.
        set signcolumn=yes

        " Map :CR to :CocRestart
        command! CR CocRestart
    """ }

    """ { coc.nvim completion options
        " Also adapted from the coc.nvim example config.
        " https://github.com/neoclide/coc.nvim#example-vim-configuration

        " NOTE: An item is always selected by default, you may want to enable
        " no select by `"suggest.noselect": true` in your configuration file.

        " Required for the next snippet
        function! CheckBackspace() abort
            let col = col('.') - 1
            return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        " Tab to navigate to next autocompletion suggestion
        " Shift+Tab to navigate to previous autocompletion suggestion
        "
        " If you want to simulate the 'noinsert' option, you can pass 0 (falsy)
        " into coc#pum#next() & coc#pum#prev() instead of 1 (truthy).
        " See `:help coc#pum#next`
        inoremap <silent><expr> <TAB>
            \ coc#pum#visible() ? coc#pum#next(1) :
            \ CheckBackspace() ? "\<Tab>" :
            \ coc#refresh()
        inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

        " Enter to confirm selection or notify coc.nvim to format
        " NOTE: <C-g>u breaks current undo, please make your own choice.
        " NOTE: This breaks abbreviations that include <CR>. Switch to snippets.
        inoremap <expr> <CR> coc#pum#visible() ? coc#pum#confirm()
            \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
    """ }

    """ { CoC statusline
        " Info: `help coc-status`
        " set statusline^=%{coc#status()}
        " augroup coc_stuff
        "     autocmd!
        "     # Automatically refresh statusline
        "     autocmd User CocStatusChange redrawstatus
        "     " Try to enable the inlay hints as soon as vim loads
        "     autocmd VimEnter :RustSetInlayHints<Enter> silent " When opening vim
        "     autocmd CursorHold :RustSetInlayHints<Enter> silent " Keep trying
        " augroup END
    """ }

    """ { Old vim built-in completion options
        " coc.nvim does not use vim's builtin completion, so these options are
        " not respected. See :help coc-completion for more info.

        " Set completeopt to have a better completion experience
        " - :help completeopt
        " - menuone: popup even when there's only one match
        " - noinsert: Do not insert text until a selection is made
        " - noselect: Do not select, force user to select one from the menu
        set completeopt=menuone,noinsert,noselect

        " Make <Enter> input a newline if no item was selected in the
        " autocomplete pop up menu ('pum')
        " - See 'pumvisible()' in :help eval.txt
        " inoremap <expr> <CR> pumvisible() ?
        "     \ (complete_info().selected == -1 ? '<C-y><CR>' : '<C-y>') :
        "     \ '<CR>'

        " Avoid showing extra messages when using completion
        " set shortmess+=c
    """ }

""" }

""" { GitHub Copilot config
    " Use <Ctrl-Tab> to accept a Copilot suggestion
    " Disable the tab mapping since it conflicts with CoC autocompletion
    imap <silent><script><expr> <C-Tab> copilot#Accept("\<CR>")
    let g:copilot_no_tab_map = v:true
""" }

""" { Plugin Options - avante.nvim

    " Load avante.nvim Lua modules when plugin becomes available
    augroup avante_group
        autocmd!
        autocmd User avante.nvim
          \ lua require('avante_lib').load() |
          \ lua require('avante').setup()
        call plug#end()
    augroup END

    " Dev recommands a global statusline (`set laststatus=3`) to enable full
    " view collapsing, but I don't like how this impacts filename display.
    " set laststatus=3
""" }


""" { Restart rust-analyzer

    " Use :RestartRustAnalyzer to quickly restart the rust-analyzer instance
    " started by the Neovim's native language server integration. Thanks GPT-4!
    " function! RestartRustAnalyzer() abort
    "     let l:bufnr = bufnr('%')
    "     let l:server_name = 'rust_analyzer'
    "     call luaeval('vim.lsp.stop_client(vim.lsp.get_active_clients())')
    "     let l:client_id = luaeval('vim.lsp.start_client({ cmd = { "rust-analyzer" } })')
    "     call luaeval('vim.lsp.buf_attach_client(' .. l:bufnr .. ', ' .. l:client_id .. ')')
    "     echo "Rust Analyzer has been restarted successfully."
    " endfunction
    " command! RestartRustAnalyzer call RestartRustAnalyzer()
""" }

""" { nvim-lspconfig General
    " https://github.com/neovim/nvim-lspconfig#rust_analyzer

    " Default minimal config - insufficient
    " lua require'lspconfig'.rust_analyzer.setup{}

    " Need loadOutDirsFromCheck for compiled .proto files (confirmed err o.w.)
    " - See: https://crates.io/crates/tonic

" lua << EOF
" local nvim_lsp = require'lspconfig'

" local on_attach = function(client)
"     require'completion'.on_attach(client)
" end

" nvim_lsp.rust_analyzer.setup({
"     on_attach=on_attach,
"     settings = {
"         ["rust-analyzer"] = {
"             assist = {
"                 importGranularity = "module",
"                 importPrefix = "by_self",
"             },
"             cargo = {
"                 -- Enable or disable features
"                 -- features = "all",
"                 -- Required to see compiled .proto
"                 loadOutDirsFromCheck = true,
"             },
"             diagnostics = {
"                 -- Prevents cfg'd code from being all underlined as warning
"                 disabled = {"inactive-code"},
"             },
"             procMacro = {
"                 enable = true
"             },
"         }
"     }
" })
" EOF

""" }

""" { Old nvim LSP code navigation shortcuts, other settings
    " Some examples which can be integrated
    " https://github.com/sharksforarms/vim-rust/blob/master/neovim-init-lsp-cmp-rust-tools.vim

    " <Leader>d or double click: Go to definition
    " nnoremap <silent> <Leader>d     <cmd>lua vim.lsp.buf.definition()<CR>
    " nnoremap <silent> <2-LeftMouse> <cmd>lua vim.lsp.buf.definition()<CR>

    " nnoremap <silent> gh    <cmd>lua vim.lsp.buf.hover()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
    " Just shows local usages
    " nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR> 
    " nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
    " nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
    " nnoremap <silent> <LocalLeader>f <cmd>lua vim.lsp.buf.references()<CR>
    " nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
    " nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>

    " augroup auto_set_inlay_hints
    "     autocmd!
    "     " Try to enable the inlay hints as soon as vim loads
    "     autocmd VimEnter :RustSetInlayHints<Enter> silent " When opening vim
    "     autocmd CursorHold :RustSetInlayHints<Enter> silent " Keep trying
    " augroup END
""" }

""" { nvim-lspconfig simrat39/rust-tools.nvim
    " lua require('rust-tools').setup({})

    " This doesn't seem to be required?
    " lua require('rust-tools.inlay_hints').set_inlay_hints()

    " Commands: 
    " nnoremap <LocalLeader>i :RustSetInlayHints<Enter>
    " nnoremap <LocalLeader>di :RustDisableInlayHints<Enter>
    " - RustToggleInlayHints
    " nnoremap <LocalLeader>r :RustRunnables<Enter>
    " nnoremap <LocalLeader>d :RustDebuggables<Enter>
    " - RustExpandMacro
    " - RustOpenCargo 
    " - RustParentModule
    " - RustJoinLines
    " First command opens the window, second command enters it
    " This one is already covered by lsp
    " nnoremap <LocalLeader>h :RustHoverActions<Enter>
    " - RustHoverRange
    " nnoremap <LocalLeader>md :RustMoveItemDown<Enter>
    " nnoremap <LocalLeader>mu :RustMoveItemUp<Enter>
    " - RustStartStandaloneServerForBuffer 
    " - RustViewCrateGraph (requires dot from graphviz)

""" }

""" Plugin options - Color Schemes
    """ Prerequisites
    " set termguicolors     " Required for most, already set elsewhere
    " syntax enable         " Required for most, already set in plug#end()

    """ Toggles
    " let g:airline_theme = 'badwolf'
    " colorscheme badwolf

    " let g:airline_theme = 'tender'
    " colorscheme tender

    let g:lightline.colorscheme = 'gruvbox'
    let g:airline_theme = 'gruvbox'
    " Can be 'soft', 'medium' or 'hard'
    let g:gruvbox_contrast_dark = 'hard'
    colorscheme gruvbox
    " More configs at https://github.com/morhetz/gruvbox/wiki/Configuration

    " let g:airline_theme = 'gruvbox-material'
    " colorscheme gruvbox-material

    " let g:airline_theme = 'iceberg'
    " colorscheme iceberg

    " let g:airline_theme = 'material'
    " let g:material_theme_style = 'ocean' " Use `ocean` or `darker`
    " colorscheme material

    " let g:airline_theme = 'alduin'
    " let g:alduin_Shout_Dragon_Aspect = 1 " Almost black background
    " let g:alduin_Shout_Become_Ethereal = 1 " Black background
    " colorscheme alduin
"""
