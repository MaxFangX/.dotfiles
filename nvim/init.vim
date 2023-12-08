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

""" { Mappings - Leader Keys
    " These are first because they are used throughout the file.

    " Main leader key <Space>
    " This setting must occur before any mapping that uses <leader>
    " '\' is the default setting.
    let mapleader = "\<Space>"

    " Local leader key -
    " This is meant for mappings that are used much less frequently,
    " or are language-specific
    let maplocalleader = "-"
""" }

""" { 'Learn Vimscript the Hard Way' exercises

    " Echoing messages: Display friendly cat when opening vim
    echo "Welcome back! >^.^<"

    " Mapping keys: Map \ to delete the current line(s),
    " then paste it below the one we're on now
    nnoremap \ ddp
    " In visual mode, also reselect text
    xnoremap \ dp`[V`]

    " Quickly edit init.vim in the midst of coding
    " (v)im: (e)dit my init.vim
    nnoremap <leader>ve :vsplit $MYVIMRC<cr>
    " (v)im: (s)ource my init.vim
    nnoremap <leader>vs :source $MYVIMRC<cr>

    " Abbreviations to fix typos
    iabbrev adn and
    iabbrev waht what
    iabbrev teh the

    " Operator-Pending Mappings
    " '(i)nside/(a)round (n)ext/(l)ast parenthesis () on this line'
    onoremap in( :<c-u>normal! f(vi(<cr>
    onoremap in) :<c-u>normal! f(vi(<cr>
    onoremap an( :<c-u>normal! f(va(<cr>
    onoremap an) :<c-u>normal! f(va(<cr>
    onoremap il( :<c-u>normal! F)vi)<cr>
    onoremap il) :<c-u>normal! F)vi)<cr>
    onoremap al( :<c-u>normal! F)va)<cr>
    onoremap al) :<c-u>normal! F)va)<cr>
    " '(i)nside/(a)round (n)ext/(l)ast brackets [] on this line'
    onoremap in[ :<c-u>normal! f[vi[<cr>
    onoremap in] :<c-u>normal! f[vi[<cr>
    onoremap an[ :<c-u>normal! f[va[<cr>
    onoremap an] :<c-u>normal! f[va[<cr>
    onoremap il[ :<c-u>normal! F]vi]<cr>
    onoremap il] :<c-u>normal! F]vi]<cr>
    onoremap al[ :<c-u>normal! F]va]<cr>
    onoremap al] :<c-u>normal! F]va]<cr>
    " '(i)nside/(a)round (n)ext/(l)ast curly braces {} on this line'
    onoremap in{ :<c-u>normal! f{vi{<cr>
    onoremap in} :<c-u>normal! f{vi{<cr>
    onoremap an{ :<c-u>normal! f{va{<cr>
    onoremap an} :<c-u>normal! f{va{<cr>
    onoremap il{ :<c-u>normal! F}vi}<cr>
    onoremap il} :<c-u>normal! F}vi}<cr>
    onoremap al{ :<c-u>normal! F}va}<cr>
    onoremap al} :<c-u>normal! F}va}<cr>
    " '(i)nside/(a)round (n)ext/(l)ast angle brackets <> on this line'
    onoremap in< :<c-u>normal! f<vi<<cr>
    onoremap in> :<c-u>normal! f<vi<<cr>
    onoremap an< :<c-u>normal! f<va<<cr>
    onoremap an> :<c-u>normal! f<va<<cr>
    onoremap il< :<c-u>normal! F>vi><cr>
    onoremap il> :<c-u>normal! F>vi><cr>
    onoremap al< :<c-u>normal! F>va><cr>
    onoremap al> :<c-u>normal! F>va><cr>
    " '(i)nside/(a)round (n)ext/(l)ast double quotes "" on this line'
    onoremap in" :<c-u>normal! f"vi"<cr>
    onoremap an" :<c-u>normal! f"va"<cr>
    onoremap il" :<c-u>normal! F"vi"<cr>
    onoremap al" :<c-u>normal! F"va"<cr>
    " '(i)nside/(a)round (n)ext/(l)ast single quotes '' on this line'
    onoremap in' :<c-u>normal! f'vi'<cr>
    onoremap an' :<c-u>normal! f'va'<cr>
    onoremap il' :<c-u>normal! F'vi'<cr>
    onoremap al' :<c-u>normal! F'va'<cr>
""" }

" # --- CONFIGURATION --- #

""" { Configuration - Tabs

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

    " Do smart autoindenting when starting a line
    set smartindent
""" }

""" { Configuration - Splits
    " Split files below and to the right
    set splitbelow
    set splitright

    " Maintain equal splits when the window size changes.
    set equalalways " this is default value
    augroup equal_splits
        autocmd!
        autocmd VimResized * wincmd =
    augroup END
""" }

""" { Configuration - UI
    " Show line numbers
    set number

    " Show (partial) command in status line
    " e.g. "-- INSERT --" "-- VISUAL --"
    " Disabled because it appears to be set by vim-airline
    " set showcmd

    " Show a right margin at 80 characters and 100 characters
    set colorcolumn=80,100

    " Always keep at least 2 lines above / below the cursor
    set scrolloff=2
""" }

""" { Configuration - Search
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
""" }

""" { Configuration - Files
    " Ignore these files in vim
    set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.DS_Store
    set wildignore+=*/node_modules/*,*/build/*,*/target/*,*/dist/*

    " Force saving files that require root permission 
    cmap w!! w !sudo tee > /dev/null %
""" }

""" { Configuration - Typing

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
""" }

""" Configuration - Relative line numbers {
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

""" { Configuration - Aesthetics
    " Use 'True colors' (16 million colors)
    " More info: https://gist.github.com/XVilka/8346728
    set termguicolors

    " When set to "dark", Vim will try to use colors that look
    " good on a dark background. When set to "light", Vim will
    " try to use colors that look good on a light background.
    set background=dark
""" }

" # --- MAPPINGS --- #

""" { Command mode mappings
    " Replace ':vhelp' with ':vert help' to open in vertical split
    cabbrev vhelp vert help

    " Replace :Q with :q; sometimes accidentally make it caps
    cabbrev Q q
""" }

""" { Mappings - Press <Leader>= to re-equalize splits
    nnoremap <Leader>= <C-W>=
""" }

""" { Mappings - Search
    " Search for visually selected text with //
    xnoremap // y/<C-R>"<CR>

    " Use # as * but without immediately skipping to the next one
    nnoremap # *N

    " m to repeat the last action then jump to next
    nnoremap m .n

    " Use M as m
    nnoremap M m
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

    " Option + j/k (DVORAK) to move screen up/down by 6 lines
    nnoremap ç 6<C-e>
    nnoremap √ 6<C-y>

    " Use the more intentional Q to record macro, q is a no-op
    nnoremap Q q
    nnoremap q <Nop>
""" }

""" { QWERTY J/K to quickly move cursor up/down by 8 lines

    " Normal mode
    nnoremap H 8j
    nnoremap T 8k

    " Visual mode
    xnoremap H 8j
    xnoremap T 8k

    " Command mode
    onoremap H 8j
    onoremap T 8k
""" }

""" { QWERTY H/L to quickly move forward/back one (blank-separated) word

    " Normal mode
    nnoremap D B
    nnoremap N W

    " Visual mode
    xnoremap D B
    xnoremap N W

    " Command mode
    onoremap D B
    onoremap N W
""" }

""" { Mouse settings

    " Enable clicking around to move cursor position
    set mouse=a

    " Enter select mode ('normal text editor' mode) using the mouse
    " instead of the unergonomic gh or gH
    set selectmode=mouse
""" }

""" { DVORAK - Splits
    " Option+d,h,t,n to switch splits
    nnoremap ˙ <C-W>h
    nnoremap ∆ <C-W>j
    nnoremap ˚ <C-W>k
    nnoremap ¬ <C-W>l

    " ctrl+W then d,h,t,n to switch splits
    nnoremap <C-W>d <C-W>h
    nnoremap <C-W>h <C-W>j
    nnoremap <C-W>t <C-W>k
    nnoremap <C-W>n <C-W>l

    " ctrl+W then D,H,T,N to move splits
    nnoremap <C-W>D <C-W>H
    nnoremap <C-W>H <C-W>J
    nnoremap <C-W>T <C-W>K
    nnoremap <C-W>N <C-W>L
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

    " Apply during visual mode
    xnoremap d h
    xnoremap h j
    xnoremap t k
    xnoremap n l

    " Has to apply during commands as well, such as delete up, yank down
    " Only for up and down, kk
    onoremap h j
    onoremap t k

    " k or K for delete (Think: "(k)ill")
    nnoremap k d
    nnoremap K D
    " apply during visual mode as well
    xnoremap k d
    xnoremap K D
    " kk to delete line: the second k is in command mode
    onoremap k d

    " j and J for find next and prev (Think: "down (j)")
    nnoremap j n
    nnoremap J N

    " L for Join lines (which was just overridden by find prev) (Think: "(L)ine")
    nnoremap L J
""" }

""" { Emacs in vim because I'm a blasphemer

    """ SIMPLE MAPPINGS: Doesn't require advanced configuration

    " With vim-rsi and Karabiner, the following work (in insert mode):
    " - Control+a/e to go to beginning / end of line
    " - Control+f/b/j/k left hand arrow keys
    "   - Note: Ctrl+f/b in normal mode will move view forward / back a page
    " - Control+u/i/o/p two-handed arrow keys
    " - Control+w to delete one word back

    " Ctrl + a / Ctrl + e to go to beginning / end
    nnoremap <C-a> ^
    nnoremap <C-e> $
    xnoremap <C-a> ^
    xnoremap <C-e> $
    onoremap <C-a> ^
    onoremap <C-e> $

    " Control+k to delete to end of line
    inoremap <C-k> <Esc>lDa

    " Control+t to transpose letters
    inoremap <C-t> <Esc>xpa

    """ ITERM2 MAPPING SETUP:
    " - Remove conflicting iTerm2 profile mappings from ALL profiles:
    "   - Preferences > Profiles > Keys
    "   - Remove Option + Up/Down/Left/Right
    "   - Remove Shift + Up/Down/Left/Right
    " - Add the iTerm2 key bindings
    "   - Prefs > Keys > Key Bindings 'Send Text with vim Special Chars'
    "   - <M-t><M-g><M-i><M-o> becomes \<M-t>\<M-g>\<M-i>\<M-o>
    "   - Import from maxfangx.itermkeymap in dotfiles to save time
    " - See Obsidian notes: 'Emacs in Vim', 'iTerm2', `zsh`, `Oh My Zsh`
    "
    " Adding New Mappings:
    " - iTerm2 maps macOS keys to meta keys not used by zsh or Oh My Zsh
    " - Vim maps meta keys to corresponding functions
    " - Since there are more shortcuts than available meta keys, the meta keys
    "   are combined in different permutations, achieving up to n! combinations
    "   - Available Meta+keys for permuting: gijknoptvyz
    "     - All other Meta+keys used in zsh, Oh My Zsh, or a vim plugin
    "   - Reserved for later: jknpz
    "     - Ctrl+z to undo, Ctrl+shift+z to redo?
    "   - Used: giot
    "   - Unused: vy
    " - There may be a cleaner approach, but this works perfectly fine
    " - iTerm2 is also capable of mapping macOS keys to hex, octals, control
    "   keys, form feed, and others... see docs for more information:
    "   https://iterm2.com/documentation-preferences-profiles-keys.html

    """ DELETE: Applies to Insert and Normal mode

    " Delete Words:
    " Control + Option + h: Delete word back
    " - <C-g>u<C-w> instead of <Esc>ldbi so it works at end of line
    "   Thanks to tim-pope/vim-rsi for the solution
    " NOTE: Additional iTerm2 mapping: Option + Delete
    " NOTE: Additional iTerm2 mapping: Control + Option + Delete
    inoremap <M-t><M-g><M-i><M-o> <C-g>u<C-w>
    " Control + Option + d: Delete word forward
    inoremap <M-t><M-g><M-o><M-i> <Esc>ldwi

    """ MOVEMENT: Applies to all (Insert, Normal, and Visual) modes

    " Letter Movement: Overwrite the default page up/down to
    " forward / back in normal mode
    " - This enables full left-handed arrow keys using Control+jkfb
    nnoremap <C-f> l
    nnoremap <C-b> h

    " Word Movement: Insert AND normal modes
    " Control + Option + f: Move forward a word
    " NOTE: Additional iTerm2 mapping: Option + Right
    " - Will also enable the Control + Option + o variant
    inoremap <M-t><M-o><M-g><M-i> <Esc>lwi
    nnoremap <M-t><M-o><M-g><M-i> w
    xnoremap <M-t><M-o><M-g><M-i> w
    " Control + Option + b: Move back a word
    " NOTE: Additional iTerm2 mapping: Control + Option + Left
    " - Will also enable the Control + Option + y variant
    inoremap <M-t><M-o><M-i><M-g> <Esc>lbi
    nnoremap <M-t><M-o><M-i><M-g> b
    xnoremap <M-t><M-o><M-i><M-g> b

    " Paragraph Movement: Insert AND normal modes
    " - iTerm2 mappings are not required for Control + key versions
    " Option + down (or Command + Control + u): Go to end of paragraph
    inoremap <M-g><M-t><M-i><M-o> <Esc>}a
    nnoremap <M-g><M-t><M-i><M-o> }
    xnoremap <M-g><M-t><M-i><M-o> }
    " Option + up (or Command + Control + i): Go to start of paragraph
    inoremap <M-g><M-t><M-o><M-i> <Esc>{a
    nnoremap <M-g><M-t><M-o><M-i> {
    xnoremap <M-g><M-t><M-o><M-i> {

    " Up Down Movement: Works out of the box
    " - Up/Down or Command + j/k or Control + u/i Insert mode
    " - Up/Down or Command + j/k or Control + u/i Normal mode
    " - Up/Down or Command + j/k or Control + u/i Visual mode

    " Home End Movement: Insert AND normal modes
    " - iTerm2 mapping is not required for Control + key versions
    "
    " Command + left: Go to beginning of line
    " - Command + Control + u works without additional iTerm2 mapping
    " NOTE: Additional iTerm2 mapping: Command + h
    inoremap <M-o><M-g><M-t><M-i> <Esc>^i
    nnoremap <M-o><M-g><M-t><M-i> ^
    xnoremap <M-o><M-g><M-t><M-i> ^
    " Command + right: Go to end of line
    " - Command + Control + i works without additional iTerm2 mapping
    " NOTE: Additional iTerm2 mapping: Command + l
    inoremap <M-o><M-i><M-t><M-g> <Esc>$a
    nnoremap <M-o><M-i><M-t><M-g> $
    xnoremap <M-o><M-i><M-t><M-g> $

    " Top Bottom Movement: Insert AND normal modes
    " - iTerm2 mapping is not required for Control + key versions
    "
    " Command + down (or Command + Control + u): Go to bottom of page
    " NOTE: Additional iTerm2 mapping: Command + j
    inoremap <M-t><M-i><M-g><M-o> <Esc>Gi
    nnoremap <M-t><M-i><M-g><M-o> G
    " Command + up (or Command + Control + i): Go to top of page
    " NOTE: Additional iTerm2 mapping: Command + k
    inoremap <M-t><M-i><M-o><M-g> <Esc>ggi
    nnoremap <M-t><M-i><M-o><M-g> gg

    """ SELECT:
    " - Insert / normal mode begins the select, visual mode continues it

    " Select Letter:
    " Shift + Control + f: Select forward a letter
    " NOTE: Additional iTerm2 mapping: Shift + Right
    " - Shift + Control + o works without additional iTerm2 mapping
    inoremap <M-o><M-t><M-g><M-i> <Esc>lv
    xnoremap <M-o><M-t><M-g><M-i> l
    nnoremap <M-o><M-t><M-g><M-i> vl
    " Shift + Control + b: Select backward a letter
    " NOTE: Additional iTerm2 mapping: Shift + Left
    " - Shift + Control + y works without additional iTerm2 mapping
    inoremap <M-o><M-t><M-i><M-g> <Esc>v
    xnoremap <M-o><M-t><M-i><M-g> h
    nnoremap <M-o><M-t><M-i><M-g> vh

    " Select Word:
    " Shift + Option + Control + f: Select forward a word
    " NOTE: Additional iTerm2 mapping: Option + Shift + Right
    " - Shift + Control + Option + o works without additional mapping
    inoremap <M-i><M-t><M-g><M-o> <Esc>lve
    xnoremap <M-i><M-t><M-g><M-o> e
    nnoremap <M-i><M-t><M-g><M-o> ve
    " Shift + Option + Control + b: Select backward a word
    " NOTE: Additional iTerm2 mapping: Option + Shift + Left
    " - Shift + Control + Option + y works without additional mapping
    inoremap <M-i><M-t><M-o><M-g> <Esc>vb
    xnoremap <M-i><M-t><M-o><M-g> b
    nnoremap <M-i><M-t><M-o><M-g> vb

    " Select Paragraph:
    " Shift + Option + Down: Select to end of paragraph
    " - Shift + Option + Control + u works without additional mapping
    inoremap <M-i><M-g><M-t><M-o> <Esc>lv}
    xnoremap <M-i><M-g><M-t><M-o> }
    nnoremap <M-i><M-g><M-t><M-o> v}
    " Shift + Option + Up: Select to beginning of paragraph
    " - Shift + Option + Control + i works without additional mapping
    inoremap <M-i><M-o><M-t><M-g> <Esc>v{
    xnoremap <M-i><M-o><M-t><M-g> {
    nnoremap <M-i><M-o><M-t><M-g> v{

    " Select Up Down:
    " Shift + Control + u: Select down
    " - Shift + Down works without additional iTerm2 mapping
    inoremap <M-g><M-i><M-t><M-o> <Esc>lvj
    xnoremap <M-g><M-i><M-t><M-o> j
    nnoremap <M-g><M-i><M-t><M-o> vj
    " Shift + Control + i: Select up
    " - Shift + Up works without additional iTerm2 mapping
    inoremap <M-g><M-o><M-t><M-i> <Esc>vk
    xnoremap <M-g><M-o><M-t><M-i> k
    nnoremap <M-g><M-o><M-t><M-i> vk

    " Select Home End:
    " Shift + Command + Right
    " - Shift + Command + Control + o works without additional mapping
    inoremap <M-g><M-i><M-o><M-t> <Esc>lv$
    xnoremap <M-g><M-i><M-o><M-t> $
    nnoremap <M-g><M-i><M-o><M-t> v$
    " Shift + Command + Left
    " - Shift + Command + Control + y works without additional mapping
    inoremap <M-g><M-o><M-i><M-t> <Esc>v^
    xnoremap <M-g><M-o><M-i><M-t> ^
    nnoremap <M-g><M-o><M-i><M-t> hv^

    " Select Top Bottom:
    " Shift + Command + Down
    " - Shift + Command + Control + u works without additional mapping
    inoremap <M-o><M-g><M-i><M-t> <Esc>lvG
    xnoremap <M-o><M-g><M-i><M-t> G
    nnoremap <M-o><M-g><M-i><M-t> vG
    " Shift + Command + Up
    " - Shift + Command + Control + i works without additional mapping
    inoremap <M-o><M-i><M-g><M-t> <Esc>vgg
    xnoremap <M-o><M-i><M-g><M-t> gg
    nnoremap <M-o><M-i><M-g><M-t> hvgg

    " Unmapped:
    inoremap <M-i><M-g><M-o><M-t> unmapped
    inoremap <M-i><M-o><M-g><M-t> unmapped
""" } 

""" { Mappings - Redo
    " Option + r (DVORAK) to redo last change
    nnoremap ø <C-R>
""" }

""" { Mappings - Vim paste (i.e. with p)

    " Don't overwrite yank register when pasting over existing text
    " in visual mode
    " http://stackoverflow.com/questions/290465/vim-how-to-paste-over-without-overwriting-register
    xnoremap p pgvy
""" }

""" { Mappings - OS Copy and Paste

    " Copy to OS clipboard from vim
    " Update: This overwrites the system clipboard when pasting over text in
    " vim - undesired behavior
    " :help clipboard
    " set clipboard=unnamed
    " set clipboard+=unnamedplus

    " Alt + QWERTY x to copy
    " https://stackoverflow.com/questions/41798130/copy-paste-in-iterm-vim
    vmap ≈ "*y

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

""" { General abbreviations

    " Expand 'TODO', 'FIXME', 'XXX' etc to e.g. 'TODO(max)'
    iabbrev TODO TODO(max)
    iabbrev XXX XXX(max)
    iabbrev TODOR TODO(max): Remove<Esc>
    iabbrev TODOI TODO(max): Implement<Esc>
    iabbrev FIXME FIXME(max)<Esc>
""" }

" # --- HELPER FUNCTIONS --- #

""" { Consume the space after an abbreviation
    " TODO Fix
    func Eatchar(pat)
      let c = nr2char(getchar(0))
      return (c =~ a:pat) ? '' : c
    endfunc
""" }

" # --- LANGUAGE SPECIFIC - BY FUNCTION --- #
" Type :setfiletype <C-d> to see the full list of supported filetypes

""" { Show empty space
    " Show tabs as >--- and non-breakable space chars as +
    " See :help nolist for more info
    augroup show_empty_space
        autocmd!
        autocmd FileType vim setlocal list
        autocmd FileType rust setlocal list
        autocmd FileType python setlocal list
        autocmd FileType javascript setlocal list
    augroup END
""" }

""" { Don't set maximum text width for some filetypes
    augroup max_textwidth
        autocmd!
        autocmd FileType vim setlocal textwidth=0
        autocmd FileType toml setlocal textwidth=0
    augroup END
""" }

""" { Use iff to fill out if statements
    " 'Learn Vimscript the Hard Way' exercise
    augroup iff_statements
        autocmd!
        autocmd FileType python       :iabbrev <buffer> iff if:<Left>
        autocmd FileType javascript   :iabbrev <buffer> iff if()<Left>
    augroup END
""" }

" # --- LANGUAGE SPECIFIC - BY LANGUAGE --- #

""" { Vim
    augroup vim_cmds
        autocmd!
        " Disable auto-pairs in vim configs, required for the following abbrev
        autocmd Filetype vim let b:autopairs_loaded=1
        " Expand """ to """ { """ }
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType vim :iabbrev <buffer> """ """ {<CR>""" }<Up>
    augroup END
""" }

""" { Vim quickfix lists
    augroup qf_cmds
        autocmd!
        " Open quickfix lists at the top
        autocmd FileType qf wincmd K
    augroup END
""" }

""" { Rust
    augroup rust_cmds
        autocmd!
        " Tip: Adding <Esc> to the end of an abbreviation prevents it from adding a trailing space
        " Tip: Use <C+]> (Ctrl plus '+' in DVORAK) to trigger the abbreviation
        " without adding a trailing space

        " Expand fn to fn _() {}
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> fn fn() {<Enter>}<Esc><Up>$bi
        " Expand matchr to match _ { Ok(_) => {}\nErr(e) => {} }
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> matchr match {<CR>Ok(_) => {<CR>}<CR>Err(e) => {<CR>}}<Esc>5<Up>ea
        " Expand matcho to match _ { Some(_) => {}\nNone => {} }
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> matcho match {<CR>Some(_) => {<CR>}<CR>None => {<CR>}}<Esc>5<Up>ea

        " TODO Make this trigger with 'impl Trait'
        " Expand impld to Display impl
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> impld use std::fmt::{self, Display};<CR>impl Display for_ {<CR>fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {<CR>write!(f, "{}")}}<Esc>$xxxx3<Up>f_s

        " Expand implf to From impl
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> implf impl From<_> for_ {<CR>fn from(_) -> Self {<CR>}}<Esc>3<Up>2f_s

        " Expand implfs to FromStr impl
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> implfs use std::str::FromStr;<CR>impl FromStr for_ {<CR>type Err = anyhow::Error;<CR>fn from_str(s: &str) -> Result<Self, Self::Err> {<CR>}}<Esc>4<Up>1f_s

        " Expand impla to Arbitrary impl
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> impla #[cfg(test)]<CR>use proptest::strategy::{BoxedStrategy, Strategy};<CR>#[cfg(test)]<CR>use proptest::arbitrary::Arbitrary;<CR>#[cfg(test)]<CR>use proptest::arbitrary::any;<CR>impl Arbitrary for_ {<CR>type Parameters = ();<CR>type Strategy = BoxedStrategy<Self>;<CR>fn arbitrary_with(_args: Self::Parameters) -> Self::Strategy {<CR>any::<_>()<CR>.prop_map(_)<CR>.boxed()<Esc>6<Up>01f_s

        " Expand tokio::select!
        " TODO: Broken; contains <CR> used by coc complete. Switch to snippets.
        " autocmd FileType rust :iabbrev <buffer> tokio::select! tokio::select! {<CR><out> = => {<CR>}<CR><out> = <fut> => {<CR>}}<Esc>4<Up>^Wa

        " #[allow(..)] expansions
        autocmd FileType rust :iabbrev <buffer> au #[allow(unused)] // TODO(max): Remove<Esc>
        autocmd FileType rust :iabbrev <buffer> adc #[allow(dead_code)] // TODO(max): Remove<Esc>

        " #[derive(..)] expansions:
        autocmd FileType rust :iabbrev <buffer> dsd #[derive(Serialize, Deserialize)]<Esc>
        autocmd FileType rust :iabbrev <buffer> ds #[derive(Serialize)]<Esc>
        autocmd FileType rust :iabbrev <buffer> dd #[derive(Deserialize)]<Esc>
    augroup END

    " Recurses upwards until we find a Cargo.toml.
    function! s:find_cargo_toml(dir)
        if empty(a:dir) || a:dir ==# '/'
            return ''
        elseif filereadable(a:dir . '/Cargo.toml')
            return a:dir . '/Cargo.toml'
        else
            return s:find_cargo_toml(fnamemodify(a:dir, ':h'))
        endif
    endfunction

    " NOTE: Currently using "coc.preferences.formatOnSave": true
    "
    " Every time a file is saved, run `cargo fmt` on it (thanks GPT-4!)
    " - First uses `find_cargo_toml` to find a `Cargo.toml` to pass to
    "   `--manifest-path`. The manifest path is required if vim was opened
    "   outside of a Cargo project or workspace, otherwise `cargo fmt` errors
    "   with 'Failed to find targets'.
    " - If a `Cargo.toml` was found, then we run `cargo fmt` with the manifest
    "   path, specifying the absolute path of the file to be formatted.
    " - Some projects have `rustfmt.toml` rules which require nightly rust.
    "   These rules aren't respected unless cargo fmt is run with the nightly
    "   toolchain, so we add +nightly to the cargo invocation.
    " - `redraw!` forces neovim to redraw the buffer after formatting is done.
    " augroup rust_fmt_on_save
    "     autocmd!
    "     autocmd BufWritePost *.rs
    "         \ let g:manifest_path = s:find_cargo_toml(expand('%:p:h')) |
    "         \ if !empty(g:manifest_path) |
    "         \     silent! execute "!cargo +nightly fmt --manifest-path " . g:manifest_path . " -- %:p" |
    "         \     redraw! |
    "         \ endif
    " augroup END
""" }

""" { Python
    augroup python_cmds
        autocmd!
        " Expand def to def ():
        autocmd Filetype python :iabbrev <buffer> def def():<Left><Left><Left>
        " Expand forr to for <cursor> in _:
        autocmd Filetype python :iabbrev <buffer> forr for in _:<Esc>bbbea
    augroup END
""" }

""" { Javascript
    augroup javascript_cmds
        autocmd!
        " Two space indent
        autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
        " Show tabs as >---, show non-breakable space chars as +
        " See :help nolist for more info
        autocmd FileType javascript setlocal list
    augroup END
""" }

""" { Go
    augroup go_cmds
        autocmd!
        " Go tabs
        autocmd FileType go setlocal autoindent noexpandtab tabstop=4 shiftwidth=4
    augroup END
""" }

""" { HTML
    augroup html_cmds
        autocmd!
        " Don't reflow text that exceeds 80 chars when editing html files
        autocmd FileType html setlocal textwidth=0
    augroup END
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

        """ Nix
        " Nix support, including syntax highlighting
        Plug 'LnL7/vim-nix'

        """ UI
        Plug 'preservim/nerdtree'         " File system explorer
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

    augroup _
        autocmd!
        " Start NERDTree if Vim is started with 0 file arguments or >=2 file args,
        " move the cursor to the other window if so
        " autocmd VimEnter * if argc() == 0 || argc() >= 2 | NERDTree | endif
        " autocmd VimEnter * if argc() == 0 || argc() >= 2 | wincmd p | endif

        " Open the existing NERDTree on each new tab.
        autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

        " If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
        autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
            \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

        " Exit Vim if NERDTree is the only window remaining in the only tab.
        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

        " Close the tab if NERDTree is the only window remaining in it.
        autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
    augroup END
""" }

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

    " Add 'Fzf' prefix to all fzf.vim commands
    " let g:fzf_command_prefix = 'Fzf'

    " :H to fuzzy search [neo]vim help tags
    command H Helptags

    " <Leader><Space> to open fulltext search
    " - Tab to select/deselect and move down
    " - Shift+Tab to select/deselect and move up
    " - TODO configure: ALT-A to select all, ALT-D to deselect all
    " - FIXME: <Enter> <C-t>, <C-x>, <C-v> to open selected files in
    "   current window / tabs / split / vsplit
    " See :Rg command definition with :command Rg
    nnoremap <Leader><Space> :Rg<Enter>

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
    " - The (len(<q-args>) > 0 ? <q-args> : '""') thing prevents the command
    "   from showing only an empty list if it was invoked without arguments:
    "   https://github.com/junegunn/fzf.vim/issues/419#issuecomment-872147450
    command! -bang -nargs=* RgFzfExample
        \ call fzf#vim#grep(
        \     'rg --no-heading --line-number --column --smart-case --color=always --max-count=1 ' 
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
        let command_fmt = 'rg --no-heading --line-number --column --smart-case --color=always --max-count=1 -- %s || true'
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
        \   'coc-json',
        \   'coc-rust-analyzer',
        \   'coc-flutter',
        \ ]

    " TODO(max): Integrate snippets: `:help coc-snippets`

    """ { Main keybindings
        " List of all CoC actions: `:help coc-actions`

        " <Leader>h: Hover
        nnoremap <silent> <Leader>h     :call CocActionAsync('doHover')<CR>
        " <Leader>d or double click: Go to (d)efinition of this item
        nnoremap <silent> <Leader>d     :call CocActionAsync('jumpDefinition')<CR>
        nnoremap <silent> <2-LeftMouse> :call CocActionAsync('jumpDefinition')<CR>
        " <Leader>r: Go to the definition of the (t)ype of this item
        nnoremap <silent> <Leader>t :call CocActionAsync('jumpTypeDefinition')<CR>
        " <Leader>r: Go to (r)e(f)erences of this item (includes the definition)
        nnoremap <silent> <Leader>r     :call CocActionAsync('jumpReferences')<CR>
        " <Leader>r: Go to (u)sages of this item (excludes the definition)
        nnoremap <silent> <Leader>u     :call CocActionAsync('jumpReferences')<CR>

        " <Leader>r: Structural (r)e(n)ame of this item
        nnoremap <silent> <LocalLeader>rn :call CocActionAsync('rename')<CR>
        " <Leader>r: Open a (r)e(f)acter window for this item
        nnoremap <silent> <LocalLeader>rf :call CocActionAsync('refactor')<CR>
        " <LocalLeader>i: Toggle inlay hints
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
        " Choose code action to quickfi(x) the current line, if any.
        nnoremap <silent> <LocalLeader>x <Plug>(coc-fix-current)
        " Choose code actions at (cursor).
        nnoremap <silent> <LocalLeader>cursor <Plug>(coc-codeaction-cursor)
        " Choose code actions at current (line).
        nnoremap <silent> <LocalLeader>line <Plug>(coc-codeaction-line)
        " Choose code actions of current (file).
        nnoremap <silent> <LocalLeader>file <Plug>(coc-codeaction)
        " Choose code action of current file (source).
        nnoremap <silent> <LocalLeader>source <Plug>(coc-codeaction-source)
        " Choose code actions from selected (range).
        nnoremap <silent> <LocalLeader>range <Plug>(coc-codeaction-selected)
        " Choose code action to (refactor) at the cursor position.
        nnoremap <silent> <LocalLeader>refactor <Plug>(coc-codeaction-refactor)
        " Choose code action to refactor at the (selected)
        nnoremap <silent> <LocalLeader>selected <Plug>(coc-codeaction-refactor-selected)
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
