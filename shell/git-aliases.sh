# shell/git-aliases.sh - Git aliases and functions
# Sourced by shell/common.sh
#
# Structure:
#   1. Core functions
#   2. Custom aliases (user-defined)
#   3. OMZ-derived aliases (adapted from oh-my-zsh plugins/git, MIT license)

##################
# Core functions #
##################

# Outputs `main` or `master` to stdout
function main_branch() {
    git branch | grep -o -m1 '\b\(master\|main\)\b'
}

function git_main_branch() {
    main_branch
}

function git_current_branch() {
    git symbolic-ref --quiet --short HEAD 2>/dev/null \
        || git rev-parse --short HEAD 2>/dev/null
}

# Check for develop and similarly named branches
function git_develop_branch() {
    command git rev-parse --git-dir &>/dev/null || return
    local branch
    for branch in dev devel develop development; do
        if command git show-ref -q --verify refs/heads/$branch; then
            echo $branch
            return 0
        fi
    done
    echo develop
    return 1
}

##################
# Custom aliases #
##################

# Prints the message of the most recent commit attempt, useful for retrying a
# commit if the commit failed due to e.g. GPG sign.
function failed-commit-msg() {
    INDEX=$( \
        cat $(git rev-parse --git-dir)/COMMIT_EDITMSG \
        | rg "Please enter the commit message for your changes" -n -m 1 \
        | sed -n 's/^\([0-9]*\)[:].*/\1/p' \
    )
    # TODO(max): Fix this in the case that git commit does NOT have -v passed in
    HEAD_N=$((INDEX - 1))
    echo "$(cat $(git rev-parse --git-dir)/COMMIT_EDITMSG | head -n ${HEAD_N})"
}
alias recommit='git commit -m "$(failed-commit-msg)"'

# Force push the current branch to `origin` up to the given commit
function gpfc() {
    local commit=$1
    local branch=$(git symbolic-ref --short HEAD)
    git push --force-with-lease --force-if-includes origin +$commit:$branch
}

# Run any git command with a split diff, e.g. `DD gsh`. Think 'delta-double'
alias DD="DELTA_FEATURES=+side-by-side"

# --- Status --- #

alias g="git status"

# --- Show --- #

alias gsu="git show"  # (g)it (s)how (u)nified
alias gs="DELTA_FEATURES=+side-by-side git show"
alias gss="DELTA_FEATURES=+side-by-side git show --show-signature"

# --- Add --- #

alias ga="git add"
alias ga.="git add ."
alias gap="git add --patch"

# --- Diff --- #

alias gd="DELTA_FEATURES=+side-by-side git diff"
alias gds="DELTA_FEATURES=+side-by-side git diff --staged"
alias gdu="git diff"  # unified view
alias gdsu="git diff --staged"  # unified view

bd() { git diff --name-only --diff-filter=d | xargs bat --paging=always --diff; }
bds() { git diff --staged | bat --paging=always --style=changes,header,grid,snip; }

function gas { git add "$@"; git diff --staged "$@"; }

# --- Checkout --- #

alias gch="git checkout"
function gchm() { git checkout $(main_branch); }

# --- Reset --- #

alias grhsh='git reset --soft HEAD~1'
alias grhhh='git reset --hard HEAD~1'
function grhhm() { git reset --hard origin/$(main_branch); }
alias grhhu='git fetch && git reset --hard @{u}'
alias grsm='git reset . && gchm'

# --- Commit --- #

alias gcm="git commit -m"
alias gca="git commit --verbose --amend"
alias gcan="git commit --verbose --amend --no-edit"
alias gcf="git commit -v --fixup"

# --- Fetch --- #

alias gf="git fetch"
alias gfo="git fetch origin"
alias gfu="git fetch upstream"

# --- Push --- #

alias gp="git push"
alias gpf='git push --force-with-lease --force-if-includes'
alias gpff="git push --force"
alias gpo="git push origin"
alias gpom="git push origin master"
function gpone { git push origin "$@":"$(git symbolic-ref --short HEAD)"; }
function gpfone { git push --force-with-lease --force-if-includes origin "$@":"$(git symbolic-ref --short HEAD)"; }

# --- Pull --- #

alias gl="git pull"
alias glor="git pull origin"
alias glu="git pull upstream"
function glum() { git fetch upstream && git merge --ff-only upstream/$(main_branch); }

alias glr="git pull --rebase"
alias glror="git pull --rebase origin"
function glrum() { git pull --rebase upstream $(main_branch); }
function glrorm() { git pull --rebase origin $(main_branch); }

# --- Fast-forward (update branches without switching) --- #

function gffom() { git fetch origin $(main_branch):$(main_branch); }
function gffum() { git fetch upstream $(main_branch):$(main_branch); }
function gffo() { git fetch origin $(git_current_branch):$(git_current_branch); }
function gffu() { git fetch upstream $(git_current_branch):$(git_current_branch); }
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

# --- Sync (ff from upstream, push to origin) --- #

function gsync() {
    git pull --ff-only upstream $(git_current_branch) && \
    git push origin $(git_current_branch)
}
# Updates master; works whether on master or not
function gsyncm() {
    local main=$(main_branch)
    if [[ $(git_current_branch) == "$main" ]]; then
        git pull --ff-only upstream "$main" && git push origin "$main"
    else
        gffum && git push origin "$main"
    fi
}

# --- Merge --- #

alias gm="git merge"
alias gmf="git merge --ff-only"
function gmm() { git merge "$(git_main_branch)"; }

# --- Stash --- #

alias gst="git stash --include-untracked"
alias gsta="git stash apply"
alias gstd="git stash drop"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gsts="git stash show --text"

# --- Branch --- #

alias gb="git branch"
alias gbr="git branch -r"

# --- Rebase --- #

alias grb="git rebase"
alias grbi="git rebase -i"
alias grbia="git rebase -i --autosquash"
alias grbc="git rebase --continue"
alias grbs="git rebase --skip"
function grbm() { git rebase $(main_branch); }
function grbim() { git rebase -i $(main_branch); }
function grbiam() { git rebase -i --autosquash $(main_branch); }
function glrbm() { git fetch origin $(main_branch):$(main_branch) && git rebase $(main_branch); }

# --- Misc --- #

alias grm="git rm"
alias gbl="git blame"

alias grs="git restore"
alias grss="git restore --staged"
grsr() {
    git fetch && \
    git reset --soft @{u} && \
    git restore --worktree --source=HEAD -- .
}

alias gsur="git submodule update --recursive"
alias gsuri="git submodule update --recursive --init"

#######################
# OMZ-derived aliases #
#######################
# Adapted from oh-my-zsh plugins/git (MIT license)
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
#
# Aliases below are included for completeness but may not be actively used.
# TODO(max): Remove unused ones.

# --- Add --- #
alias gaa='git add --all'
alias gau='git add --update'
alias gav='git add --verbose'

# --- Branch --- #
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'

# --- Checkout --- #
alias gco='git checkout'
alias gcb='git checkout -b'
function gcd() { git checkout $(git_develop_branch); }
function gcM() { git checkout $(git_main_branch); }

# --- Cherry-pick --- #
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# --- Commit --- #
alias gc='git commit --verbose'
alias gcmsg='git commit --message'
alias gcsm='git commit --signoff --message'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'
alias gcam='git commit --all --message'

# --- Diff --- #
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gdw='git diff --word-diff'

# --- Log --- #
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glg='git log --stat'
alias glgp='git log --stat --patch'

# --- Merge --- #
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'
function gmom() { git merge origin/$(git_main_branch); }
function gmum() { git merge upstream/$(git_main_branch); }

# --- Pull --- #
alias gpr='git pull --rebase'
alias gprv='git pull --rebase -v'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'
function gprom() { git pull --rebase origin $(git_main_branch); }
function gprum() { git pull --rebase upstream $(git_main_branch); }
function gluc() { git pull upstream $(git_current_branch); }

# --- Push --- #
alias gpd='git push --dry-run'
alias gpv='git push --verbose'
alias gpu='git push upstream'
alias gpod='git push origin --delete'
function gpsup() { git push --set-upstream origin $(git_current_branch); }
function gpoat() { git push origin --all && git push origin --tags; }

# --- Rebase --- #
alias grba='git rebase --abort'
alias grbo='git rebase --onto'
function grbd() { git rebase $(git_develop_branch); }
function grbom() { git rebase origin/$(git_main_branch); }
function grbum() { git rebase upstream/$(git_main_branch); }

# --- Remote --- #
alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'

# --- Reset --- #
alias grh='git reset'
alias grhh='git reset --hard'
alias grhs='git reset --soft'
function groh() { git reset origin/$(git_current_branch) --hard; }

# --- Restore --- #
alias grst='git restore --staged'

# --- Revert --- #
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'

# --- Show --- #
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'

# --- Stash --- #
alias gstc='git stash clear'
alias gstaa='git stash apply'
alias gstall='git stash --all'

# --- Status --- #
alias gss='git status --short'
alias gsb='git status --short --branch'

# --- Switch --- #
alias gsw='git switch'
alias gswc='git switch --create'
function gswd() { git switch $(git_develop_branch); }
function gswm() { git switch $(git_main_branch); }

# --- Tag --- #
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

# --- Worktree --- #
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# --- Other --- #
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias gcount='git shortlog --summary --numbered'
alias gfg='git ls-files | grep'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gclean='git clean --interactive -d'
alias gcl='git clone --recurse-submodules'
alias grmc='git rm --cached'
alias ghh='git help'
alias grf='git reflog'
alias gsi='git submodule init'
alias gsu_='git submodule update'  # gsu conflicts with custom alias

# WIP functions
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'

function grename() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: grename old_branch new_branch"
        return 1
    fi
    git branch -m "$1" "$2"
    if git push origin :"$1"; then
        git push --set-upstream origin "$2"
    fi
}
