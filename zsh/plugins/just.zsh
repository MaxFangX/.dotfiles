# just command runner completions
# Works with fzf-tab for fuzzy recipe selection

if (( $+commands[just] )); then
    eval "$(just --completions zsh)"
fi
