# Zsh completion configuration
#
# Abridged vendor of ~/.oh-my-zsh/lib/completion.zsh
# - Removed COMPLETION_WAITING_DOTS feature
# - Removed ignored-patterns for uninteresting users
#
# MIT License
# Copyright (c) 2009-2024 Robby Russell and contributors
# https://github.com/ohmyzsh/ohmyzsh

zmodload -i zsh/complist

WORDCHARS=''

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end

# Menu selection with highlighting
bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*:*:*:*:*' menu select

# Case insensitive, partial-word and substring completion
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# Colorize completions
zstyle ':completion:*' list-colors ''

# Process completion
zstyle ':completion:*:*:kill:*:processes' list-colors \
    '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command \
    "ps -u $USERNAME -o pid,user,comm -w -w"

# Directory completion ordering
zstyle ':completion:*:cd:*' tag-order \
    local-directories directory-stack path-directories

# Use caching for expensive completions
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# Load bash completion functions
autoload -U +X bashcompinit && bashcompinit
