# shell/git-aliases.sh - Git aliases and functions
# Sourced by shell/common.sh

###########################
# Core functions
###########################

# Outputs `main` or `master` to stdout
function main_branch() {
    git branch | grep -o -m1 '\b\(master\|main\)\b'
}

function unalias_idempotent() {
    alias "$1" >/dev/null 2>&1 && unalias "$1"
}

function git_main_branch() {
    main_branch
}

function git_current_branch() {
    git symbolic-ref --quiet --short HEAD 2>/dev/null \
        || git rev-parse --short HEAD 2>/dev/null
}

###########################
# Custom aliases
###########################

# Prints the message of the most recent commit attempt, useful for retrying a
# commit if the commit failed due to e.g. GPG sign.
function failed-commit-msg() {
    # (1) Take the failed commit msg, (2) find the start of the useless part,
    # (3) extract the line number only, then (4) assign the result to INDEX.
    INDEX=$( \
        cat $(git rev-parse --git-dir)/COMMIT_EDITMSG \
        | rg "Please enter the commit message for your changes" -n -m 1 \
        | sed -n 's/^\([0-9]*\)[:].*/\1/p' \
    )
    # Subtract 1 and assign to HEAD_N, which we'll pass to `head -n`
    # TODO(max): Fix this in the case that git commit does NOT have -v passed in
    HEAD_N=$((INDEX - 1))
    # Echo the result
    echo "$(cat $(git rev-parse --git-dir)/COMMIT_EDITMSG | head -n ${HEAD_N})"
}
# Retry the most recent failed commit using the same commit message as before
alias recommit='git commit -m "$(failed-commit-msg)"'

# Force push the current branch to `origin` up to the given commit
function gpfc() {
  local commit=$1
  local branch=$(git symbolic-ref --short HEAD)
  git push --force-with-lease --force-if-includes origin +$commit:$branch
}

# Run any git command with a split diff, e.g. `DD gshs`. Think 'delta-double'
alias DD="DELTA_FEATURES=+side-by-side"

# --- Status ---

alias g="git status"
unalias_idempotent gsb  # OMZ git status --short --branch
unalias_idempotent gst  # OMZ git status
unalias_idempotent gss  # OMZ git status -s

# --- Show ---

unalias_idempotent gsh  # OMZ git show
alias gsu="git show"  # (g)it (s)how (u)nified
alias gs="DELTA_FEATURES=+side-by-side git show"
alias gss="DELTA_FEATURES=+side-by-side git show --show-signature"

# --- Add ---

alias ga="git add"
alias ga.="git add ."
alias gap="git add --patch"

# --- Diff ---

alias gd="DELTA_FEATURES=+side-by-side git diff"
alias gds="DELTA_FEATURES=+side-by-side git diff --staged"
alias gdd="git diff"  # unified view
alias gdds="git diff --staged"  # unified view

# Syntax-highlighted diff with bat
bd() { git diff --name-only --diff-filter=d | xargs bat --paging=always --diff }
bds() { git diff --staged | bat --paging=always --style=changes,header,grid,snip }

function gas { git add "$@"; git diff --staged "$@"; }

# --- Checkout ---

alias gch="git checkout"
function gchm() { git checkout `main_branch` }

# --- Reset ---

alias grhsh='git reset --soft HEAD~1'
alias grhhh='git reset --hard HEAD~1'
function grhhm() { git reset --hard origin/`main_branch` }
alias grhhu='git fetch && git reset --hard @{u}'
alias grsm='git reset . && gchm'

# --- Commit ---

alias gcm="git commit -m"
alias gca="git commit --verbose --amend"
alias gcan="git commit --verbose --amend --no-edit"
alias gcf="git commit -v --fixup"

# --- Fetch ---

# OMZ has already set gf and gfo to "git fetch" and "git fetch origin"
alias gfu="git fetch upstream"

# --- Push ---

alias gp="git push"
# OMZ sets gpf to --force-with-lease
alias gpff="git push --force"
alias gpo="git push origin"
alias gpom="git push origin master"
# Push one commit to origin/<current-branch>
function gpone { git push origin "$@":"$(git symbolic-ref --short HEAD)" }
function gpfone { git push --force-with-lease --force-if-includes origin "$@":"$(git symbolic-ref --short HEAD)" }

# --- Pull ---

alias gl="git pull"
alias glor="git pull origin"
alias glu="git pull upstream"
unalias_idempotent glum  # OMZ: git pull upstream master
# Update current branch from upstream main/master with fast-forward only
function glum() { git fetch upstream && git merge --ff-only upstream/`main_branch` }

alias glr="git pull --rebase"
alias glror="git pull --rebase origin"
function glrum() { git pull --rebase upstream `main_branch` }
function glrorm() { git pull --rebase origin `main_branch` }

# --- Fast-forward (update branches without switching) ---

# Uses fetch with refspec for safety - will fail if not a fast-forward
function gffom() { git fetch origin `main_branch`:`main_branch` }
function gffum() { git fetch upstream `main_branch`:`main_branch` }
function gffo() { git fetch origin $(git_current_branch):$(git_current_branch) }
function gffu() { git fetch upstream $(git_current_branch):$(git_current_branch) }
function gff() {
  local current_branch=$(git_current_branch)
  local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
  if [[ -z "$upstream" ]]; then
    echo "Error: No upstream configured for branch '$current_branch'"
    return 1
  fi
  local remote=${upstream%%/*}
  local remote_branch=${upstream#*/}
  git fetch "$remote" "$remote_branch:$current_branch"
}

# --- Merge ---

# gm is 'git merge'
alias gmf="git merge --ff-only"
function gmm() { git merge "$(git_main_branch)"; }

# --- Stash ---

alias gst="git stash --include-untracked"
alias gsta="git stash apply"
alias gstd="git stash drop"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gsts="git stash show --text"
unalias_idempotent gstaa  # OMZ git stash apply
unalias_idempotent gstc   # OMZ git stash clear
unalias_idempotent gstall # OMZ git stash --all

# --- Branch ---

alias gb="git branch"
alias gbr="git branch -r"

# --- Rebase ---

alias grb="git rebase"
alias grbi="git rebase -i"
alias grbia="git rebase -i --autosquash"
alias grbc="git rebase --continue"
alias grbs="git rebase --skip"
function grbm() { git rebase `main_branch` }
function grbim() { git rebase -i `main_branch` }
function grbiam() { git rebase -i --autosquash `main_branch` }
function glrbm() {
    git fetch origin `main_branch`:`main_branch` && git rebase `main_branch`
}

# --- Misc ---

alias grm="git rm"
alias gbl="git blame"

alias grs="git restore"
alias grss="git restore --staged"
# Pull remote changes as unstaged while keeping staged changes intact
grsr() {
  git fetch && \
  git reset --soft @{u} && \
  git restore --worktree --source=HEAD -- .
}

alias gsur="git submodule update --recursive"
alias gsuri="git submodule update --recursive --init"
