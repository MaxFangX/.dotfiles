
""" { ctrl+W then d,h,t,n to switch splits
noremap <C-W>d <C-W>h
noremap <C-W>h <C-W>j
noremap <C-W>t <C-W>k
noremap <C-W>n <C-W>l
"""" }

""" { jk for Esc key, but is ht under DVORAK
imap ht <Esc>
""" }

""" { Fix weird hjkl positioning under DVORAK
"(n)
noremap d h
noremap h gj
noremap t gk
noremap n l

" Apply during visual and select modes
" (v)
noremap d h
noremap h gj
noremap t gk
noremap n l

" Has to apply during commands as well, such as delete up, yank down
" Only for up and down, kk
" (o)
noremap h gj
noremap t gk

" k or K for delete (Think: "(k)ill")
" "(n)
noremap k d
noremap K D
" apply during visual and select modes as well
" (v)
noremap k d
noremap K D
" kk to delete line: the second k is in command mode
"(o)
noremap k d

" j and J for find next and prev (Think: "down (j)")
"(n)"
noremap j n
noremap J N

" L for Join lines (which was just overridden by find prev) (Think: "(L)ine")
"(l)
noremap L J
""" }

""" { emacs movements in vim because Mac has turned me into a blasphemer
"(n)"
nmap <C-a> ^
nmap <C-e> $
"""

""" { Fix emacs movements in insert mode again
imap <C-a> <Esc>I
imap <C-e> <Esc>A
""" }
