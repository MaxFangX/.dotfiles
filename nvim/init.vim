""" { Notes

    " Config Docs: See http://vimdoc.sourceforge.net/htmldoc/options.html

    " For multi-byte character support (CJK support, for example):
    " set fileencodings=ucs-bom,utf-8,cp936,big5,euc-jp,euc-kr,gb18030,latin1

"""

""" { Basic usability - Tabs

    " Insert space characters whenever the tab key is pressed
    " https://vim.fandom.com/wiki/Converting_tabs_to_spaces
    " Use the appropriate number of spaces to insert a <Tab>.
    " Spaces are used in indents with the '>' and '<' commands
    " and when 'autoindent' is on. To insert a real tab when
    " 'expandtab' is on, use CTRL-V <Tab>.
    set expandtab

    " When on, a <Tab> in front of a line inserts blanks
    " according to 'shiftwidth'. 'tabstop' is used in other
    " places. A <BS> will delete a 'shiftwidth' worth of space
    " at the start of the line.
    set smarttab

    " Supposedly required for correct indent
    set tabstop=4

    " Number of spaces to use for each step of (auto)indent
    set shiftwidth=4

    " Copy indent from current line when starting a new line
    " (typing <CR> in Insert mode or when using the "o" or "O"
    " command).
    set autoindent
""" }

""" { Basics - Split location
    " Split files below and to the right
    set splitbelow
    set splitright
""" }

""" { Basics - UI
    " Show line numbers
    set number

    " Show (partial) command in status line
    " e.g. "-- INSERT --" "-- VISUAL --"
    " Disabled because it appears to be set by vim-airline
    " set showcmd

    " Show a right margin at 80 characters
    set colorcolumn=80
""" }

""" { Basics - Search
    " When there is a previous search pattern, highlight all
    " its matches.
    " set hlsearch

    " While typing a search command, show immediately where the
    " so far typed pattern matches.
    set incsearch

    " Ignore case in search patterns.
    set ignorecase 

    " Override the 'ignorecase' option if the search pattern
    " contains upper case characters.
    set smartcase

    " Search for visually selected text with //
    vnoremap // y/<C-R>"<CR>
""" }

""" { Basics - Files
    " Ignore these files in vim
    set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.DS_Store
    set wildignore+=*/node_modules/*,*/build/*,*/target/*,*/dist/*

    " Force saving files that require root permission 
    cmap w!! w !sudo tee > /dev/null %
""" }

""" { Normal mode mods
    " Option+v (DVORAK) to enter visual block mode
    nnoremap ≥ <C-v>

    " Option + f/b (QWERTY) for half page down/up
    " Note: Other combinations contain curly quotes in the Option mapping
    " causing the page up/down to require two taps rather than one.
    " Have tried F/B and D/U in both QWERTY and DVORAK mappings and this
    " was the only working version.
    nnoremap ƒ <C-D>
    nnoremap ∫ <C-U>
""" }

""" { Mouse settings

    " Enable clicking around to move cursor position
    set mouse=a
""" }

""" { Leader Key
    " This setting must occur before any mapping that uses <leader>
    " Consider '\' (default) or ',' as alternatives
    let mapleader = ' '
""" }

""" { DVORAK - Splits
    " Option+d,h,t,n to switch splits
    noremap ˙ <C-W>h
    noremap ∆ <C-W>j
    noremap ˚ <C-W>k
    noremap ¬ <C-W>l

    " ctrl+W then d,h,t,n to switch splits
    noremap <C-W>d <C-W>h
    noremap <C-W>h <C-W>j
    noremap <C-W>t <C-W>k
    noremap <C-W>n <C-W>l
"""" }

""" { DVORAK - hn for Esc key
    " l at the end because the cursor moves left one tick by default
    inoremap hn <Esc>l
""" }

""" { DVORAK - Fix weird hjkl positioning
    nnoremap d h
    nnoremap h j
    nnoremap t k
    nnoremap n l

    " Apply during visual and select modes
    vnoremap d h
    vnoremap h j
    vnoremap t k
    vnoremap n l

    " Has to apply during commands as well, such as delete up, yank down
    " Only for up and down, kk
    onoremap h j
    onoremap t k

    " k or K for delete (Think: "(k)ill")
    nnoremap k d
    nnoremap K D
    " apply during visual and select modes as well
    vnoremap k d
    vnoremap K D
    " kk to delete line: the second k is in command mode
    onoremap k d

    " j and J for find next and prev (Think: "down (j)")
    nnoremap j n
    nnoremap J N

    " L for Join lines (which was just overridden by find prev) (Think: "(L)ine")
    nnoremap L J
""" }

""" { Emacs navigation in vim because I'm a blasphemer
    
    " Normal mode Ctrl + a / Ctrl + e to go to beginning / end
    nmap <C-a> ^
    nmap <C-e> $

"""

""" { Typing - Emacs

    " With vim-rsi and Karabiner, the following work (in insert mode):
    " - Ctrl+a/e to go to beginning / end of line
    " - Ctrl+f/b/j/k left hand arrow keys
    "   - Note: Ctrl+f/b in normal mode will move view forward / back a page
    " - Ctrl+u/i/o/p two-handed arrow keys
    " - Ctrl+w to delete one word back

    " Ctrl+k to delete to end of line
    inoremap <C-k> <Esc>lDa

    " TODO: Delete word with option+delete, option+ctrl+i, etc
""" } 

""" { Typing - General

    " When a bracket is inserted, briefly jump to the matching
    " one. The jump is only done if the match can be seen on the
    " screen. The time to show the match can be set with
    " 'matchtime'.
    set showmatch

    " Default text width of 80
    set textwidth=80

    " Try these if you have backspace problems
    " https://vim.fandom.com/wiki/Backspace_and_delete_problems
    " set backspace=2
    " set backspace=indent,eol,start

    " Automatic formatting

    " A sequence of letters which describes how automatic formatting
    " is to be done.
    "
    " letter    meaning when present in 'formatoptions'
    " ------    ---------------------------------------
    " c         Auto-wrap comments using textwidth, inserting
    "           the current comment leader automatically.
    " q         Allow formatting of comments with "gq".
    " r         Automatically insert the current comment leader
    "           after hitting <Enter> in Insert mode. 
    " t         Auto-wrap text using textwidth (does not apply
    "           to comments)
    set formatoptions=c,q,r,t 

    " Option + r (DVORAK) to redo last change
    nnoremap ø <C-R>
""" }


""" Relative line numbers {
    " http://jeffkreeftmeijer.com/2012/relative-line-numbers-in-vim-for-super-fast-movement/
    set relativenumber

    " Ctrl + n to switch between relative and absolute
    function! NumberToggle()
      if(&relativenumber == 1)
        set number
      else
        set relativenumber
      endif
    endfunc
    nnoremap <C-n> :call NumberToggle()<cr>
    
    " Set/unset when lose/gain focus
    :au FocusLost * :set number
    :au FocusGained * :set relativenumber
""" }

""" { Vim Copy and Paste (i.e. with p)

    " Don't overwrite yank register when pasting over existing text
    " in visual mode
    " http://stackoverflow.com/questions/290465/vim-how-to-paste-over-without-overwriting-register
    xnoremap p pgvy
""" }

""" { OS Copy and Paste

    " Copy to OS clipboard from vim
    " Update: This overwrites the system clipboard when pasting over text in
    " vim - undesired behavior
    " :help clipboard
    " set clipboard=unnamed
    " set clipboard+=unnamedplus

    " Alt + QWERTY c to copy
    " https://stackoverflow.com/questions/41798130/copy-paste-in-iterm-vim
    vmap ç "*y
    vmap √ "*p

    " This alternative way to do it doesn't seem to work
    " https://stackoverflow.com/questions/677986/vim-copy-selection-to-os-x-clipboard
    " vmap <C-x> :!pbcopy<CR>  
    " vmap <C-c> :w !pbcopy<CR><CR> 

    " Avoid undesired side-effects while pasting
    " This hack automatically toggles :set paste just prior to a paste and
    " and toggles back to :set nopaste immediately after paste
    " https://stackoverflow.com/a/38258720
    " Haven't confirmed if this is still needed in Neovim
    let &t_SI .= "\<Esc>[?2004h"
    let &t_EI .= "\<Esc>[?2004l"
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
    function! XTermPasteBegin()
        set pastetoggle=<Esc>[201~
        set paste
        return ""
    endfunction
""" }

""" { Language-specific Python
    " For tabs, > is shown at the beginning, - throughout
    autocmd FileType python setlocal listchars=tab:>-

    " Show empty spaces
    " set list
""" }

""" { Language-specific - Javascript
    " Two space indent
    " For tabs, > is shown at the beginning, - throughout
    autocmd FileType javascript setlocal listchars=tab:>-
    autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
""" }

""" { Language-specific - Go
    " Go tabs
    autocmd FileType go setlocal autoindent noexpandtab tabstop=4 shiftwidth=4
""" }

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

        Plug 'preservim/nerdtree'       " File system explorer
        Plug 'kien/ctrlp.vim'           " Fuzzy file search
        Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

        """ For code completion
        Plug 'ycm-core/YouCompleteMe'

        """ Rust - simrat39/rust-tools.nvim
        " Common LSP configs
        Plug 'neovim/nvim-lspconfig'
        Plug 'simrat39/rust-tools.nvim'
        " Optional dependencies
        Plug 'nvim-lua/popup.nvim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-telescope/telescope.nvim'
        " Debugging (needs plenary from above as well)
        Plug 'mfussenegger/nvim-dap'

        """ Pretty and helpful bottom bar
        Plug 'vim-airline/vim-airline'  

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

""" { vim-surround

    " Remove mapping since ds is is causing moving left to require two keystrokes
    " https://github.com/tpope/vim-surround/blob/master/plugin/surround.vim#L599
    let g:surround_no_mappings = '1'

    " Manually add back key mappings, replacing ds with ks
    nmap ks     <Plug>Dsurround
    nmap cs     <Plug>Csurround
    nmap cS     <Plug>CSurround
    nmap ys     <Plug>Ysurround
    nmap yS     <Plug>YSurround
    nmap yss    <Plug>Yssurround
    nmap ySs    <Plug>YSsurround
    nmap ySS    <Plug>YSsurround
    xmap S      <Plug>VSurround
    xmap gS     <Plug>VgSurround
    imap <C-S>  <Plug>Isurround
    imap <C-G>s <Plug>Isurround
    imap <C-G>S <Plug>ISurround
""" }

""" { NERDTree
    " Toggle show NERDTree with Option+8
    nnoremap • :NERDTreeToggle<Enter>

    " No existing mapping h
    " Undo existing mapping t
    let NERDTreeMapOpenInTab='<Nul>'
    " No existing mapping v
    " Undo existing mapping s
    let NERDTreeMapOpenVSplit='<Nul>'
    " Undo existing mapping T
    let NERDTreeMapOpenInTabSilent='<Nul>'

    " Set my own mappings
    let NERDTreeMenuDown='h'      " Navigation
    let NERDTreeMenuUp='t'        " Navigation
    let NERDTreeMapOpenVSplit='v' " vsplit
    let NERDTreeMapOpenSplit='s'  " split
    " let NERDTreeMenuOpenInTabSilent='T' " can't get tab to work
    " let NERDTreeMenuOpenInTab='T'       " can't get tab to work

    " Start NERDTree when Vim is started without file arguments.
    autocmd StdinReadPre * let s:std_in=1
    autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif

    " Start NERDTree if Vim is started with 0 file arguments or >=2 file args,
    " move the cursor to the other window if it was started with >= 2 file args
    autocmd VimEnter * if argc() == 0 || argc() >= 2 | NERDTree | endif
    autocmd VimEnter * if argc() >= 2 | wincmd p | endif

    " Open the existing NERDTree on each new tab.
    autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

    " Exit Vim if NERDTree is the only window remaining in the only tab.
    autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

    " Close the tab if NERDTree is the only window remaining in it.
    autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

    " If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
    autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
        \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

""" }

""" { CtrlP

    " Change default mapping to Option+P (QWERTY)
    let g:ctrlp_map = 'π'

    " Movement mappings
    let g:ctrlp_prompt_mappings = {
        \     'PrtSelectMove("h")': ['<c-h>', '<down>'],
        \     'PrtSelectMove("t")': ['<c-t>', '<up>'],
        \ }

    " Disable jump to file if it's already open, so it's easy to open multiple
    " splits of the same file
    let g:ctrlp_switch_buffer = 0

    " CtrlP-specific ignore
    let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist|DS_Store)|(\.(swp|ico|git|svn))$'

    " Use with ripgrep
    " https://www.philipbradley.net/posts/2017-03-29-ripgrep-with-ctrlp-and-vim/
    if executable('rg')
      let g:ctrlp_user_command = 'rg --files %s'
      let g:ctrlp_use_caching = 0
      let g:ctrlp_working_path_mode = 'ra'
    endif
""" }

""" { Plugin Options - rust-analyzer
    " Set completeopt to have a better completion experience
    " :help completeopt
    " menuone: popup even when there's only one match
    " noinsert: Do not insert text until a selection is made
    " noselect: Do not select, force user to select one from the menu
    set completeopt=menuone,noinsert,noselect

    " Avoid showing extra messages when using completion
    " set shortmess+=c
""" }

""" { nvim-lspconfig General
    " https://github.com/neovim/nvim-lspconfig#rust_analyzer

    " Default minimal config - insufficient
    " lua require'lspconfig'.rust_analyzer.setup{}

    " Need loadOutDirsFromCheck for compiled .proto files (confirmed err o.w.)
    " - See: https://crates.io/crates/tonic

lua << EOF
local nvim_lsp = require'lspconfig'

local on_attach = function(client)
    require'completion'.on_attach(client)
end

nvim_lsp.rust_analyzer.setup({
    on_attach=on_attach,
    settings = {
        ["rust-analyzer"] = {
            assist = {
                importGranularity = "module",
                importPrefix = "by_self",
            },
            cargo = {
                loadOutDirsFromCheck = true -- Required to see compiled .proto
            },
            procMacro = {
                enable = true
            },
        }
    }
})
EOF




""" }

""" { Code navigation shortcut examples - integrate these
    " https://github.com/sharksforarms/vim-rust/blob/master/neovim-init-lsp-cmp-rust-tools.vim

    " Go to definition
    nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
    " Go back
    nnoremap <silent> <c-[> <c-^>

    nnoremap <silent> D     <cmd>lua vim.lsp.buf.hover()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
    " Just shows local usages
    " nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR> 
    " nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
    " nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
    nnoremap <silent> grf    <cmd>lua vim.lsp.buf.references()<CR>
    " nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
    " nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
    " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>

    " Try to enable the inlay hints as soon as vim loads
    autocmd VimEnter :RustSetInlayHints<Enter> silent " When opening vim
    autocmd CursorHold :RustSetInlayHints<Enter> silent " Keep trying
""" }


""" { nvim-lspconfig simrat39/rust-tools.nvim
    lua require('rust-tools').setup({})

    " Not sure if this is required
    lua require('rust-tools.inlay_hints').set_inlay_hints()


    " Commands: 
    nnoremap grs :RustSetInlayHints<Enter>
    " - RustDisableInlayHints
    " - RustToggleInlayHints
    nnoremap grr :RustRunnables<Enter>
    nnoremap grd :RustDebuggables<Enter>
    " - RustExpandMacro
    " - RustOpenCargo 
    " - RustParentModule
    " - RustJoinLines
    " First command opens the window, second command enters it
    " nnoremap grh :RustHoverActions<Enter> " Already covered by lsp
    " - RustHoverRange
    nnoremap grmd :RustMoveItemDown<Enter>
    nnoremap grmu :RustMoveItemUp<Enter>
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

    let g:airline_theme = 'gruvbox'
    colorscheme gruvbox

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

""" { Aesthetics
    " Use 'True colors' (16 million colors)
    " Info: https://gist.github.com/XVilka/8346728
    set termguicolors

    " When set to "dark", Vim will try to use colors that look
    " good on a dark background. When set to "light", Vim will
    " try to use colors that look good on a light background.
    set background=dark
""" }

