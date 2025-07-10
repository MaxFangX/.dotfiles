""" { Core VIM config
    " Core configs which are dependency-free and safe to install on remote VMs.
    source ~/.config/nvim/core.vim
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
