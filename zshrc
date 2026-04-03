# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#########################
# ZSH-SPECIFIC SETTINGS #
#########################

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.

# Disable oh-my-zsh theming - we use our own
ZSH_THEME=""
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# See also: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Plugins are now vendored in zsh/plugins/
plugins=()

# Init Oh My Zsh
if [ -f $ZSH/oh-my-zsh.sh ]; then
    source $ZSH/oh-my-zsh.sh
    fpath=($(brew --prefix)/share/zsh-completions $fpath)
else
    # Non-OMZ: set up completion and options manually
    autoload -Uz compinit && compinit
    zstyle ':completion:*' matcher-list \
        'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
    setopt auto_cd
    setopt interactivecomments
    setopt share_history
    setopt hist_ignore_dups
    setopt hist_expire_dups_first
    setopt extended_history
    setopt hist_verify

    # Up/down arrow prefix search
    autoload -U up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey "^[[A" up-line-or-beginning-search
    bindkey "^[[B" down-line-or-beginning-search

    # Ctrl+Left/Right - move by word
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word

    # Home/End
    bindkey "^[[H" beginning-of-line
    bindkey "^[[F" end-of-line

    # Shift+Tab - reverse completion menu
    bindkey "^[[Z" reverse-menu-complete

    # Ctrl+x Ctrl+e - edit command in $EDITOR
    autoload -U edit-command-line
    zle -N edit-command-line
    bindkey "^X^E" edit-command-line

    # Directory navigation (vendored from OMZ)
    source ~/.dotfiles/zsh/lib/directories.zsh
fi

# Load theme and vendored plugins
source ~/.dotfiles/zsh/maxfangx.zsh-theme
source ~/.dotfiles/zsh/plugins/rust.zsh
source ~/.dotfiles/zsh/plugins/fzf.zsh

# Theme switching functions
_reset_theme() {
  PROMPT='' RPROMPT='' PS2=''
  unset ${(k)parameters[(I)ZSH_THEME_*]} 2>/dev/null
}
theme-maxfangx() { _reset_theme && source ~/.dotfiles/zsh/maxfangx.zsh-theme; }
theme-bitcoin() { _reset_theme && source ~/.dotfiles/zsh/bitcoin.zsh-theme; }

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# gh copilot aliases
if [ -x "$(command -v gh)" ]; then
    eval "$(gh copilot alias -- zsh)"
fi

# Turn '$' into a no-op to allow easily copy-pasting commands
alias -g '$'=''

###########################
# GENERAL SETTINGS
###########################

# Load Home Manager session variables
if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi

# Load settings common to both bash and zsh
source ~/.dotfiles/shell/common.sh

# Load zsh-specific git enhancements (after common.sh loads git-aliases.sh)
source ~/.dotfiles/zsh/plugins/git.zsh
