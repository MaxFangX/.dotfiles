#!/usr/bin/env bash
set -euo pipefail

# Remove a git worktree and its associated branch.
# Usage: just -g worktree remove <dir> [git-worktree-remove-args...]

dir="$1"
shift
args="$*"

# Detect --force/-f so we can also force-delete the branch below.
force=false
if [[ " $args " == *" --force "* || " $args " == *" -f "* ]]; then
    force=true
fi

# Read the branch before removal — the entry disappears with the worktree.
# Key on the absolute path, not a name derived from the worktree path, which
# can differ wildly (e.g. paseo's `.paseo/worktrees/<id>/<animal-name>`).
# `cd` failing means the dir is already gone; fall back to $dir, which paseo
# passes as an absolute path and still matches the porcelain listing.
abs_dir="$(cd "$dir" 2>/dev/null && pwd -P || echo "$dir")"
branch="$(git worktree list --porcelain | awk -v d="$abs_dir" '
    $1 == "worktree" { wt = $2 }
    $1 == "branch" && wt == d { sub(/^refs\/heads\//, "", $2); print $2 }
')"

# Resolve the repo's default branch instead of assuming main vs master.
# origin/HEAD is authoritative; fall back to whichever common name exists.
# `|| true` so a missing origin/HEAD yields empty (handled below) rather than
# tripping `set -e` via pipefail.
default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
if [[ -z "$default_branch" ]]; then
    for name in main master; do
        if git show-ref --verify --quiet "refs/heads/$name"; then
            default_branch="$name"
            break
        fi
    done
fi
default_branch="${default_branch:-main}"

git worktree remove $args "$dir"

# Delete the worktree's branch only if it's been merged (or --force is set).
#
# Try the fast local ancestry check first. It only works for merge commits
# and fast-forwards, though: GitHub "Rebase and merge" replays commits with
# new hashes, so the branch tip isn't an ancestor of the default branch and
# `git branch -d` would refuse it. In that case ask `gh` whether the PR
# merged, and force `-D` if it did.
if [[ -z "$branch" ]]; then
    # Detached HEAD: no branch to delete.
    echo "Removed worktree at $dir (no associated branch to delete)"
elif [[ "$branch" == "$default_branch" ]]; then
    # Never delete the default branch, even with --force.
    echo "Removed worktree at $dir"
    echo "Refusing to delete default branch '$branch'"
elif git merge-base --is-ancestor "$branch" "$default_branch" 2>/dev/null; then
    # Tip is reachable from the default branch (merge / fast-forward); safe to -d.
    git branch -d "$branch"
    echo "Removed worktree at $dir and deleted branch '$branch'"
elif command -v gh &>/dev/null && [[ "$(gh pr list --head "$branch" --state merged --json number --jq 'length' 2>/dev/null || echo 0)" != "0" ]]; then
    # GitHub confirmed the merge; force-delete since -d can't see rebased commits.
    git branch -D "$branch"
    echo "Removed worktree at $dir and deleted branch '$branch' (PR merged)"
elif [[ "$force" == true ]]; then
    # --force was used on the worktree; honor it for the branch too.
    git branch -D "$branch"
    echo "Removed worktree at $dir and force-deleted branch '$branch'"
else
    echo "Removed worktree at $dir"
    echo "Branch '$branch' not deleted (no merged PR and not an ancestor of '$default_branch')"
    echo "To delete: git branch -D $branch"
fi
