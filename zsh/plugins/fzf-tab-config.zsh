# fzf-tab configuration

# Disable sort for git commands (show in git's natural order)
zstyle ':completion:*:git-*:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Colorize completions using LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Disable default completion menu (let fzf-tab handle it)
zstyle ':completion:*' menu no

# Switch between groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# Theme: red accents, white text (matches maxfangx.zsh-theme)
zstyle ':fzf-tab:*' fzf-flags \
    --color=fg:7,fg+:15,bg+:-1,hl:1,hl+:1 \
    --color=pointer:1,marker:1,info:1,prompt:1,border:1 \
    --pointer='>' \
    --marker='*'

# Group colors: white for first group, red for second, then alternating
zstyle ':fzf-tab:*' group-colors \
    $'\x1b[97m' $'\x1b[91m' $'\x1b[97m' $'\x1b[91m' \
    $'\x1b[97m' $'\x1b[91m' $'\x1b[97m' $'\x1b[91m'

# Preview directory contents when completing cd
if (( $+commands[eza] )); then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
elif (( $+commands[ls] )); then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
fi
