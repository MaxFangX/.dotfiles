# Terminal colors setup
#
# Abridged vendor of ~/.oh-my-zsh/lib/theme-and-appearance.zsh
# - Only LS_COLORS/LSCOLORS setup (for fd, ls, etc.)
#
# MIT License
# Copyright (c) 2009-2024 Robby Russell and contributors
# https://github.com/ohmyzsh/ohmyzsh

# BSD-based ls (macOS)
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# GNU-based ls and tools (fd, eza, etc.)
# Check for dircolors (Linux) or gdircolors (macOS via Homebrew coreutils)
if [[ -z "$LS_COLORS" ]]; then
  local _dircolors=${commands[dircolors]:-${commands[gdircolors]}}
  if [[ -n "$_dircolors" ]]; then
    [[ -f "$HOME/.dircolors" ]] \
      && source <("$_dircolors" -b "$HOME/.dircolors") \
      || source <("$_dircolors" -b)
  else
    export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
  fi
fi
