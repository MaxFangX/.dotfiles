" .vimrc
" See: http://vimdoc.sourceforge.net/htmldoc/options.html for details

" For multi-byte character support (CJK support, for example):
"set fileencodings=ucs-bom,utf-8,cp936,big5,euc-jp,euc-kr,gb18030,latin1

let base16colorspace=256
set t_Co=256

if $SIGFIGCONFIG ==# 1
    set noexpandtab
    set copyindent
    set preserveindent
    set softtabstop=0
else
    set expandtab       " Use the appropriate number of spaces to insert a <Tab>.
                        " Spaces are used in indents with the '>' and '<' commands
                        " and when 'autoindent' is on. To insert a real tab when
                        " 'expandtab' is on, use CTRL-V <Tab>.

    set smarttab        " When on, a <Tab> in front of a line inserts blanks
                        " according to 'shiftwidth'. 'tabstop' is used in other
                        " places. A <BS> will delete a 'shiftwidth' worth of space
                        " at the start of the line.
     
endif
 
set tabstop=4       " Number of spaces that a <Tab> in the file counts for.
 
set shiftwidth=4    " Number of spaces to use for each step of (auto)indent.
 
set showcmd         " Show (partial) command in status line.

set number          " Show line numbers.

set showmatch       " When a bracket is inserted, briefly jump to the matching
                    " one. The jump is only done if the match can be seen on the
                    " screen. The time to show the match can be set with
                    " 'matchtime'.
 
set hlsearch        " When there is a previous search pattern, highlight all
                    " its matches.
 
set incsearch       " While typing a search command, show immediately where the
                    " so far typed pattern matches.
 
set ignorecase      " Ignore case in search patterns.
 
set smartcase       " Override the 'ignorecase' option if the search pattern
                    " contains upper case characters.
 
set backspace=2     " Influences the working of <BS>, <Del>, CTRL-W
                    " and CTRL-U in Insert mode. This is a list of items,
                    " separated by commas. Each item allows a way to backspace
                    " over something.
 
set autoindent      " Copy indent from current line when starting a new line
                    " (typing <CR> in Insert mode or when using the "o" or "O"
                    " command).
 
 
set formatoptions=c,q,r,t " This is a sequence of letters which describes how
                    " automatic formatting is to be done.
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
 
set ruler           " Show the line and column number of the cursor position,
                    " separated by a comma.
 
set background=dark " When set to "dark", Vim will try to use colors that look
                    " good on a dark background. When set to "light", Vim will
                    " try to use colors that look good on a light background.
                    " Any other value is illegal.
 
set mouse=a         " Enable the use of the mouse.

""" Vundle settings {

    set nocompatible               " be iMproved, required
    filetype plugin on             " required
    " filetype off                 " required

    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')

    " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'
    Plugin 'Valloric/YouCompleteMe'
    Plugin 'burnettk/vim-angular'
    Plugin 'jacoborus/tender.vim'

    " All of your Plugins must be added before the following line
    call vundle#end()            " required
    filetype plugin indent on    " required

    " To ignore plugin indent changes, instead use:
    " filetype plugin on
    "
    " Brief help
    " :PluginList       - lists configured plugins
    " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
    " :PluginSearch foo - searches for foo; append `!` to refresh local cache
    " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
    "
    " see :h vundle for more details or wiki for FAQ
    " Put your non-Plugin stuff after this line

""" }

" Pathogen
execute pathogen#infect()
syntax on

let g:neocomplcache_enable_at_startup = 1
let g:indentLine_char = '│'
let g:notes_directories = ['~/Notes/']
let g:notes_suffix = '.note'

autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=8
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=8
set laststatus=2
set synmaxcol=300

""" Force saving files that require root permission 
    cmap w!! w !sudo tee > /dev/null %
"""

""" { Syntastic settings

    set statusline+=%{exists('g:loaded_syntastic_plugin')?SyntasticStatuslineFlag():''}
    " set statusline+=%#warningmsg#
    " set statusline+=%{SyntasticStatuslineFlag()}
    " set statusline+=%*

    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 0

    " disable syntastic on the statusline
    let g:statline_syntastic = 0
    
    if $SIGFIGCONFIG ==# 1
        let g:syntastic_mode_map = { 'mode': 'active', 'active_filetypes': [], 'passive_filetypes': ['html', 'javascript'] }
    else
        let g:syntastic_mode_map = { 'mode': 'active', 'active_filetypes': [], 'passive_filetypes': ['html'] }
    endif

    " To toggle error checking, ctrl+w, E
    nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>
    let g:syntastic_javascript_checkers = ['jshint', 'jsl'] 
    let g:syntastic_python_checkers = ['flake8', 'pep8', 'pyflakes', 'python']

    """ { Custom Configurations

        " Ignore line too long rule.
        let g:syntastic_python_flake8_args='--ignore=E501'
        let g:syntastic_python_pep8_args='--ignore=E501'
        " More info:
        " https://stackoverflow.com/questions/28118565/how-can-i-set-the-python-max-allowed-line-length-to-120-in-syntastic-for-vim

    """ }

""" } Syntastic settings

""" { Python two space indent
    " For tabs, > is shown at the beginning, - throughout
    autocmd FileType python setlocal listchars=tab:>-

    " Show empty spaces
    " set list
""" }

""" Re-yank text pasted in visual mode {
    " http://stackoverflow.com/questions/290465/vim-how-to-paste-over-without-overwriting-register
    xnoremap p pgvy
""" }

""" { Copy to OS clipboard from vim
    set clipboard=unnamed

    " https://stackoverflow.com/questions/41798130/copy-paste-in-iterm-vim
    vmap <C-c> "*y

    " This alternative way to do it doesn't seem to work
    " https://stackoverflow.com/questions/677986/vim-copy-selection-to-os-x-clipboard
    " vmap <C-x> :!pbcopy<CR>  
    " vmap <C-c> :w !pbcopy<CR><CR> 
""" }

""" { Javascript two space indent
    " For tabs, > is shown at the beginning, - throughout
    autocmd FileType javascript setlocal listchars=tab:>-
    autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
""" }

""" { Go tab indent
    autocmd FileType go setlocal autoindent noexpandtab tabstop=4 shiftwidth=4
""" }

""" { ctrl+j,k,h,l to switch splits
    map <C-j> <C-W>j
    map <C-k> <C-W>k
    map <C-h> <C-W>h
    map <C-l> <C-W>l
"""" } switch splits

""" { jk for Esc key
    imap jk <Esc>
""" }

""" { emacs movements in vim because Mac has turned me into a blasphemer
    nmap <C-a> ^
    nmap <C-e> $
"""

""" Fix mouse past 220th column {
    if has("mouse_sgr")
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    end
""" }

""" CtrlP
    set runtimepath^=~/.vim/bundle/ctrlp.vim
    let g:ctrlp_map = '<c-p>'
    let g:ctrlp_cmd = 'CtrlP'
    let g:ctrlp_working_path_mode = 'ra'
    let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
    let g:ctrlp_custom_ignore = {
        \ 'dir':  '\v[\/]\.(git|hg|svn)$',
        \ 'file': '\v\.(exe|so|dll)$',
        \ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
        \ }
    " CtrlPTag Shortcut: \.
    nnoremap <leader>. :CtrlPTag<cr>
""" CtrlP

""" Path {{
set path=$PWD/**
    " Sigfig
    if $SIGFIGCONFIG ==# 1
        set path+=$PWD/**/scripts/references.ts
        set path+=$PWD/**/scripts/lib/**/*.ts
        set path+=$PWD/**/scripts/app.ts
        set path+=$PWD/**/scripts/module.ts
        set path+=$PWD/**/scripts/util/**/*.ts
        set path+=$PWD/**/scripts/services/**/*wire*.ts
        set path+=$PWD/**/scripts/services/**/*.ts
        set path+=$PWD/**/scripts/**/*.{ts,tsx}
    endif
""" Path }}

""" Relative line numbers {
    " http://jeffkreeftmeijer.com/2012/relative-line-numbers-in-vim-for-super-fast-movement/

    " Ctrl + n to switch between relative and absolute
    function! NumberToggle()
      if(&relativenumber == 1)
        set number
      else
        set relativenumber
      endif
    endfunc
    nnoremap <C-n> :call NumberToggle()<cr>
    set relativenumber
    
    " Set/unset when lose/gain focus
    :au FocusLost * :set number
    :au FocusGained * :set relativenumber
""" }

""" Nerdtree {
    " Start nerdtree when opening vim if no files were specified
    autocmd StdinReadPre * let s:std_in=1
    autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
""" }

" Tagbar: F8 shortcut
nmap <F8> :TagbarToggle<CR>

" Ignore these files in vim
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " Linux/MacOSX

" Search for visually selected text with //
vnoremap // y/<C-R>"<CR>

" Splits files below and to the right
set splitbelow
set splitright

""" Automatically toggle :set paste and :set nopaste upon paste {
    let &t_SI .= "\<Esc>[?2004h"
    let &t_EI .= "\<Esc>[?2004l"
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
    function! XTermPasteBegin()
        set pastetoggle=<Esc>[201~
        set paste
        return ""
    endfunction
""" }

" Auto-wrap .tex files at 80 characters
au BufRead,BufNewFile *.tex setlocal textwidth=80

" Show a right margin at 80 characters
set colorcolumn=80

""" Color scheme {
    " If you have vim >=8.0 or Neovim >= 0.1.5
    if (has("termguicolors"))
     set termguicolors
    endif

    " For Neovim 0.1.3 and 0.1.4
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1

    " Fix for MacVim
    let macvim_skip_colorscheme=1

    " set airline theme
    let g:airline_theme = 'tender'

    " colorscheme
    syntax enable
    colorscheme tender
""" }

