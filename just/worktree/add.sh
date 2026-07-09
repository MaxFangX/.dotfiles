#!/usr/bin/env bash
set -euo pipefail

# Create a git worktree for AI development. Best run from the main worktree.
# Usage: just -g worktree add <dir>

dir="$1"

# Derive branch name from path: if the path contains "worktrees/", use
# everything after that (supports developer-namespaced branches), otherwise
# use the basename.
# e.g. ~/lexe/worktrees/satoshi/my-feature -> satoshi/my-feature
# e.g. ~/lexe/satoshi/my-feature           -> my-feature
if [[ "$dir" == *"worktrees/"* ]]; then
    branch="${dir#*worktrees/}"
else
    branch="$(basename "$dir")"
fi

# Check out the existing branch, or create it if it doesn't exist.
if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$dir" "$branch"
else
    git worktree add "$dir" -b "$branch"
fi

# Carry over the current worktree's .env (usually fresher than .env.example)
# and .vim dir, when present. Both are no-ops in repos that lack them.
if [[ -f .env ]]; then
    cp .env "$dir/.env"
fi
if [[ -d .vim ]]; then
    ln -sf "$(pwd)/.vim" "$dir/.vim"
fi

echo "Created worktree at $dir"
