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
        Plug 'jiangmiao/auto-pairs'     " Insert / delete ' '' [ { in pairs
        Plug 'ton/vim-bufsurf'          " Buffer history per window

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
