" ### --- MAXFANGX CORE NEOVIM CONFIG --- ###
"
" Max's 'core' Neovim configuration which does not require any dependencies and
" is safe to use on machines with higher security requirements.
"
" Install:
" ```bash
" mkdir -p ~/.config/nvim
" curl -Lo ~/.config/nvim/maxfangx-core.vim https://raw.githubusercontent.com/MaxFangX/.dotfiles/master/nvim/core.vim
" cp ~/.config/nvim/maxfangx-core.vim ~/.config/nvim/init.vim
" ```
"
" Unset:
" ```bash
" rm ~/.config/nvim/init.vim
" ```

""" { Vimscript notes

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
""" }

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

    " Whether the current line (at the cursor) shows relative or absolute
    " number => absolute; nonumber => relative (always 0, useless)
    set number
    " Whether other lines show relative or absolute
    " - The augroup below will override this if enabled
    " - Options: relativenumber, norelativenumber
    set norelativenumber

    " LocalLeader + n to switch between relative and absolute
    " function! RelativeNumberToggle()
    "   if(&relativenumber == 1)
    "     set norelativenumber
    "   else
    "     set relativenumber
    "   endif
    " endfunc
    " nnoremap <LocalLeader>n :call RelativeNumberToggle()<cr>

    " Set window to relative line numbers when gaining focus
    " Retvrn to absolute line numbers when losing focus
    " Apply to all filetypes except vim help
    " augroup relative_numbers_for_focused_window_only
    "     autocmd!
    "     autocmd WinEnter,FocusGained * if &filetype != 'help' | setlocal relativenumber | endif
    "     autocmd WinLeave,FocusLost * if &filetype != 'help' | setlocal norelativenumber | endif
    " augroup END
""" }

""" Configuration - Mistyped commands {
    command! Vne vnew
    command! Bd bdelete
    command! Tabe tabedit
    command! Tabc tabclose
""" }

""" Configuration - Session commands {
    " :m - Make session
    command! M mks!
    " :mwq - Make session, write all, and quit all
    command! Mwq mks! | wqa
    " :mq - Make session and quit all
    command! Mq mks! | qa
""" }

""" Configuration - Auto-reload changed files {
    " Automatically reload files changed outside of Vim
    " This is useful when files are modified by linters or AI tools
    set autoread

    " Check for file changes when:
    " - Vim gains focus
    " - Moving between windows
    " - After 4 seconds of idle time
    augroup auto_reload_changed_files
        autocmd!
        " When switching buffers, entering a window, or regaining focus
        autocmd FocusGained,BufEnter,WinEnter * if mode() != 'c' | checktime | endif
        " Check periodically when cursor stops moving, but not in search mode
        " mode() =~# '[/?]' checks if we're in search mode
        autocmd CursorHold,CursorHoldI * if mode() !~# '[/?]' | checktime | endif
    augroup END

    " Reduce the time before CursorHold triggers (default is 4000ms)
    " This makes the auto-reload more responsive
    set updatetime=1000

    " Optionally, show a message when a file is reloaded
    " (commented out by default to reduce noise)
    " autocmd FileChangedShellPost * echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
""" }

" # --- MAPPINGS --- #

""" { Command mode mappings
    " Replace ':vhelp' with ':vert help' to open in vertical split
    cabbrev vhelp vert help

    " Session commands
    cabbrev m M
    cabbrev mwq Mwq
    cabbrev mq Mq

    " Replace :Q with :q; sometimes accidentally make it caps
    " - Disabled, can't search for 'Q'
    " cabbrev Q q
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

""" { DVORAK - Fixes
    " Fix weird hjkl positioning
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

    " j/J and q/Q for next and prev (Think: "down (j)")
    "
    " - j/J below will be overridden by vim-illuminate to navigate references
    "   instead, which is much more useful than recording macros or entering Ex
    "   mode. We set these mappings only as a sane default when using a
    "   standalone core.vim on secure machines.
    " - q/Q is always mapped to n/N.
    " - <Leader>q is used to record macro, since it is done rarely.
    nnoremap j n
    nnoremap J N
    nnoremap q n
    nnoremap Q N
    nnoremap <Leader>q q


    " L for Join lines (which was just overridden by find prev) (Think: "(L)ine")
    nnoremap L J

    " `'` and `"` to till forwards / backwards (Think "tick (') to just before")
    nnoremap ' t
    xnoremap ' t
    onoremap ' t
    nnoremap " T
    xnoremap " T
    onoremap " T
""" }

""" { DVORAK - hn for Esc key
    " l at the end because the cursor moves left one tick by default
    inoremap hn <Esc>l
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
    xnoremap p "_dP

    " Modern alternative for the below: see `:help v_P`
    " xnoremap p P

    " Old map which served me for years:
    " http://stackoverflow.com/questions/290465/vim-how-to-paste-over-without-overwriting-register
    " xnoremap p pgvy
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
    xnoremap ≈ "+y
    " + is supposedly more correct than * but I don't see a difference?
    " xnoremap ≈ "*y

    " This alternative way to do it doesn't seem to work
    " https://stackoverflow.com/questions/677986/vim-copy-selection-to-os-x-clipboard
    " vmap <C-x> :!pbcopy<CR>
    " vmap <C-c> :w !pbcopy<CR><CR>

    " <Leader>y to (y)ank relative filepath to clipboard
    " <Leader>Y to (Y)ank absolute filepath to clipboard
    nnoremap <Leader>y :let @+ = fnamemodify(expand('%'), ':~:.') <Bar> let @" = @+ <Bar> echo 'Copied path: ' . @+<CR>
    nnoremap <Leader>Y :let @+ = expand('%:p') <Bar> let @" = @+ <Bar> echo 'Copied path: ' . @+<CR>

    " Auto-copy visual mode yanks to system clipboard
    " This maps y in visual mode to yank to both default and system registers
    xnoremap y "+y

    " Auto-copy yy (yank line) to system clipboard
    nnoremap yy "+yy

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

""" { Mappings - Buffer navigation
    " <Leader>p to go to (p)revious buffer
    " <Leader>n to go to (n)ext buffer
    " <Leader>N to go to previous buffer
    nnoremap <Leader>p :bp<CR>
    nnoremap <Leader>n :bn<CR>
    nnoremap <Leader>N :bp<CR>
""" }

""" { Mappings - Operator pending mappings
    " From 'Learn Vimscript the Hard Way'

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

""" { Mappings - move lines down
    " From 'Learn Vimscript the Hard Way'

    " Mapping keys: Map \ to delete the current line(s),
    " then paste it below the one we're on now
    nnoremap \ ddp
    " In visual mode, also reselect text
    xnoremap \ dp`[V`]
""" }

""" { Mappings - Terminal mode
    " <Esc> to exit terminal mode, with special handling for fzf
    " - In fzf: <Esc> exits terminal mode AND closes the window (1 keypress)
    " - In other terminals: <Esc> just exits terminal mode
    " Also disable line numbers and color column in terminal windows
    augroup terminal_escape
        autocmd!
        autocmd TermOpen * setlocal nonumber norelativenumber
            \ colorcolumn=
        autocmd TermOpen * if &filetype == 'fzf' || bufname('%') =~# 'fzf' |
            \ tnoremap <buffer> <silent> <Esc> <C-\><C-n>:close<CR> |
            \ nnoremap <buffer> <silent> q :close<CR> |
        \ else |
            \ tnoremap <buffer> <Esc> <C-\><C-n> |
        \ endif
    augroup END
""" }

""" { Mappings - Quick edit vim configs while coding
    " From 'Learn Vimscript the Hard Way'

    " Quickly edit init.vim in the midst of coding
    " (v)im: (e)dit my init.vim
    nnoremap <leader>ve :vsplit $MYVIMRC<cr>
    " (v)im: edit (c)ore.vim
    nnoremap <leader>vc :vsplit ~/.dotfiles/nvim/core.vim<cr>
    " (v)im: (s)ource my init.vim
    " After sourcing, re-apply colorscheme from lazy plugins
    nnoremap <leader>vs :source $MYVIMRC<cr>:silent! colorscheme gruvbox<cr>
""" }

""" { Abbreviations

    " Expand 'TODO', 'FIXME', 'XXX' etc to e.g. 'TODO(max)'
    iabbrev TODO TODO(max)
    " iabbrev todo TODO(max) # False positive with Rust's todo!()
    iabbrev XXX XXX(max)
    iabbrev xxx XXX(max)
    iabbrev TODOR TODO(max): Remove<Esc>
    iabbrev todor TODO(max): Remove<Esc>
    iabbrev TODOI TODO(max): Implement<Esc>
    iabbrev todoi TODO(max): Implement<Esc>
    iabbrev todod TODO(max): Document<Esc>
    iabbrev FIXME FIXME(max)<Esc>
    iabbrev fixme FIXME(max)<Esc>

    " Abbreviations to fix typos
    iabbrev adn and
    iabbrev waht what
    iabbrev teh the
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

""" { JavaScript
    augroup javascript_settings
        autocmd!
        autocmd FileType javascript setlocal
            \ shiftwidth=2
            \ tabstop=2
            \ softtabstop=2
            \ list
    augroup END
""" }

""" { JSON
    augroup json_settings
        autocmd!
        autocmd FileType json setlocal
            \ shiftwidth=2
            \ tabstop=2
            \ softtabstop=2
            \ list
    augroup END
""" }

""" { Go
    augroup go_settings
        autocmd!
        autocmd FileType go setlocal
            \ noexpandtab
            \ tabstop=4
            \ shiftwidth=4
    augroup END
""" }

""" { HTML
    augroup html_cmds
        autocmd!
        " Don't reflow text that exceeds 80 chars when editing html files
        autocmd FileType html setlocal textwidth=0
    augroup END
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

" # --- NO-DEPENDENCY COLOR SCHEME --- #

""" { This scheme is built-in.
    " Outside of a remote VM, this is overridden at the bottom of init.vim.
    colorscheme slate
    " Complete list of just-OK built-in schemes (everything else sucks):
    " - `default`
    " - `desert`
    " - `evening`
    " - `slate`
""" }
