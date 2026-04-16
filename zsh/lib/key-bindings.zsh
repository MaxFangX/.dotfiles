# Readline-style key bindings (vendored from OMZ lib/key-bindings.zsh)
# Standard emacs bindings (ctrl+a/e/b/f/d/k/u/w, alt+b/f/d) come from
# `bindkey -e` in zshrc. This file adds useful extras.

# [Esc-w] - Kill from cursor to mark
bindkey '\ew' kill-region

# [Esc-m] - Copy previous shell word (useful for file renames)
bindkey '\em' copy-prev-shell-word

# [Space] - Don't do history expansion (e.g., typing "!!" won't expand)
bindkey ' ' magic-space
