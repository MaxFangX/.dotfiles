# Directory navigation shortcuts
#
# Abridged vendor of ~/.oh-my-zsh/lib/directories.zsh
# - ls aliases removed (handled elsewhere)
#
# MIT License
# Copyright (c) 2009-2024 Robby Russell and contributors
# https://github.com/ohmyzsh/ohmyzsh

setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Expand ... to ../..
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

# Directory stack navigation
alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias md='mkdir -p'
alias rd=rmdir

function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d
