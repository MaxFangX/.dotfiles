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

" # --- PLUGIN OPTIONS --- #

""" { GitHub Copilot config
    " Use <Ctrl-Tab> to accept a Copilot suggestion
    " Disable the tab mapping since it conflicts with CoC autocompletion
    imap <silent><script><expr> <C-Tab> copilot#Accept("\<CR>")
    let g:copilot_no_tab_map = v:true
""" }
