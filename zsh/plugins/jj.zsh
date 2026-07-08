# jujutsu (jj) completions
#
# Uses jj's dynamic completions: candidates (bookmarks, revisions,
# aliases, files) are queried from the repo at completion time, so
# e.g. `jj show max/11<Tab>` completes conflicted bookmark names.
# Works with fzf-tab for fuzzy selection.

if (( $+commands[jj] )); then
    source <(COMPLETE=zsh jj)
fi
