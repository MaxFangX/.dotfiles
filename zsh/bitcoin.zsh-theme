# bitcoin theme
#
# Copyright (c) 2026 Max Fang
# Inspired by sonicradish from oh-my-zsh (MIT)
# https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/sonicradish.zsh-theme

setopt promptsubst
autoload -U colors && colors

source "${0:A:h}/lib/spectrum.zsh"
source "${0:A:h}/lib/git.zsh"

# Colors (256-color palette via $FG array)
local orange=$FG[208]
local purple=$FG[103]
local red=$FG[124]

# Root indicator
local root_icon=""
[[ $EUID -eq 0 ]] && root_icon="%{$FG[111]%}# %{$reset_color%}"

# user@host cwd (branch) $
PROMPT="${root_icon}%{$orange%}%n@%m %{$purple%}%c %{$green%}"
PROMPT+='$(git_prompt_info)'
PROMPT+="%{$orange%}$ %{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}) "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$red%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
