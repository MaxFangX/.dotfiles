# Zsh-only git enhancements
#
# Adapted from oh-my-zsh plugins/git (MIT license)
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
#
# This file provides zsh-specific features that complement shell/git-aliases.sh:
#   - Completion definitions (compdef)
#   - Version-conditional aliases
#   - Zsh-specific functions

# Git version for conditional features
autoload -Uz is-at-least
_git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

# Version-conditional aliases
# --force-if-includes was added in git 2.30
if is-at-least 2.30 "$_git_version"; then
    alias gpf='git push --force-with-lease --force-if-includes'
    alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
else
    alias gpf='git push --force-with-lease'
    alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease'
fi

# --jobs was added in git 2.8
if is-at-least 2.8 "$_git_version"; then
    alias gfa='git fetch --all --tags --prune --jobs=10'
else
    alias gfa='git fetch --all --tags --prune'
fi

# stash push vs save (push added in 2.13)
if is-at-least 2.13 "$_git_version"; then
    alias gsta_='git stash push'
else
    alias gsta_='git stash save'
fi

unset _git_version

# Completion definitions
compdef _git gcd=git-checkout 2>/dev/null
compdef _git gcM=git-checkout 2>/dev/null
compdef _git gco=git-checkout 2>/dev/null
compdef _git gcb=git-checkout 2>/dev/null
compdef _git gpsup=git-push 2>/dev/null
compdef _git gpf=git-push 2>/dev/null
compdef _git gpfc=git-push 2>/dev/null
compdef _git gpone=git-push 2>/dev/null
compdef _git gpfone=git-push 2>/dev/null
compdef _git ggl=git-pull 2>/dev/null
compdef _git grename=git-branch 2>/dev/null

# Clone and cd into directory
function gccd() {
    setopt localoptions extendedglob
    local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}"
    command git clone --recurse-submodules "$@" || return
    [[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
compdef _git gccd=git-clone 2>/dev/null

# Pretty log with custom format
function _git_log_prettily() {
    if [[ -n $1 ]]; then
        git log --pretty=$1
    fi
}
alias glp='_git_log_prettily'
compdef _git _git_log_prettily=git-log 2>/dev/null

# Diff excluding lock files
function gdnolock() {
    git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
compdef _git gdnolock=git-diff 2>/dev/null

# Diff in view
function gdv() {
    git diff -w "$@" | view -
}
compdef _git gdv=git-diff 2>/dev/null

# WIP detection for prompt
function work_in_progress() {
    command git -c log.showSignature=false log -n 1 2>/dev/null \
        | grep -q -- "--wip--" && echo "WIP!!"
}
