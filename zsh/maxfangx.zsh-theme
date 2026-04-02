# maxfangx theme
#
# Copyright (c) 2026 Max Fang
# Inspired by darkblood from oh-my-zsh (MIT)
# https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/darkblood.zsh-theme

setopt promptsubst
autoload -U colors && colors

# Source vendored git prompt functions
source "${0:A:h}/lib/git.zsh"

if [[ $OSTYPE == darwin* ]]; then
  PROMPT='%{$fg[red]%}[%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[red]%}]$ %{$reset_color%}'
else
  PROMPT='%{$fg[red]%}[%{$fg_bold[white]%}%n%{$reset_color%}%{$fg[red]%}@%{$fg_bold[white]%}%m%{$reset_color%}%{$fg[red]%}::%{$fg[white]%}%~%{$fg[red]%}]$ %{$reset_color%}'
fi
RPROMPT='%{$fg[red]%}$(git_prompt_info)%{$reset_color%}'
PS2='%{$fg[red]%}|$ %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="(%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$fg[red]%})"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
