#!/usr/bin/env bash
set -euo pipefail

# Create a colocated jj workspace (+ git worktree) at <dir>. Best run from the
# repo. The jj analog of `worktree add`: all workspaces share one commit graph
# and op log, and each gets a real `.git` so git tooling still works inside.
# Usage: just -g workspace add <dir> [--no-paseo]
# A relative <dir> that lands inside the repo is reinterpreted as a path under
# the repo's workspaces dir (see resolve-dir.sh).

source "$(dirname "${BASH_SOURCE[0]}")/resolve-dir.sh"

dir="$(resolve_workspace_dir "$1")"
shift

# By default, after creating the workspace, start a detached paseo agent
# inside it, which also registers the directory as a paseo workspace.
# --no-paseo opts out.
paseo_run=true
for arg in "$@"; do
    case "$arg" in
        --no-paseo) paseo_run=false ;;
        *)
            echo "workspace add: unknown argument '$arg'" >&2
            exit 1
            ;;
    esac
done

# `jj workspace add` creates the git worktree itself and auto-colocates (a
# real `.git` alongside `.jj`) when the current workspace is colocated. Bail
# if it isn't, rather than silently producing a non-colocated workspace.
# Colocation needs a jj built with worktree support (jj-vcs/jj#8667); see
# pkgs/jj.
root="$(jj root)"
if [[ ! -e "$root/.git" ]]; then
    echo "workspace add: this jj repo isn't colocated ($root has no .git)." >&2
    echo "Colocate the primary worktree ('jj git init --colocate' there)," >&2
    echo "or promote this one with 'just -g worktree set-primary'." >&2
    exit 1
fi

# Derive the branch name from the path, mirroring `worktree add`: everything
# after "worktrees/" or "workspaces/" (supports developer-namespaced
# branches), else the basename. jj workspace names can't contain '/', so the
# workspace is keyed by the basename while this namespaced name is the
# bookmark.
# e.g. ~/lexe/worktrees/max/07-01-foo -> bookmark max/07-01-foo, ws 07-01-foo
if [[ "$dir" == *"worktrees/"* ]]; then
    branch="${dir#*worktrees/}"
elif [[ "$dir" == *"workspaces/"* ]]; then
    branch="${dir#*workspaces/}"
else
    branch="$(basename "$dir")"
fi
name="$(basename "$dir")"

# Create the colocated workspace. Like `worktree add`, check out an existing
# bookmark at its tip; otherwise base the workspace on the current
# workspace's parent and start a fresh bookmark there.
if [[ -n "$(jj log --no-pager --no-graph -r "present($branch)" -T '"x"' 2>/dev/null)" ]]; then
    jj workspace add --name "$name" --revision "$branch" "$dir"
    new_branch=false
else
    jj workspace add --name "$name" "$dir"
    new_branch=true
fi

# Check the bookmark out in git so the worktree starts *on* the branch (its
# tip) and pushes as `$branch`. For a new branch, first point the bookmark at
# the shared parent (@-); basing at @- rather than @ keeps an empty
# working-copy commit out of the branch history. The first `jj commit`
# detaches git HEAD (jj's native model), so this `git switch` only sets the
# starting point; move the bookmark with `jj bookmark set $branch` before
# pushing.
(
    cd "$dir"
    [[ "$new_branch" == true ]] && jj bookmark create "$branch" -r @-
    jj git export
    git switch "$branch"
)

# Carry over the current worktree's .env and .vim, mirroring `worktree add`.
# Both are no-ops when absent.
if [[ -f .env ]]; then
    cp .env "$dir/.env"
fi
if [[ -d .vim ]]; then
    ln -sf "$(pwd)/.vim" "$dir/.vim"
fi

echo "Created colocated jj workspace at $dir on branch $branch"

# Make the new workspace show up in the Paseo UI by starting a detached paseo
# agent in it (sends "hi" to Opus).
#
# Terminals inside Paseo export PASEO_WORKSPACE_ID, which `paseo run` prefers
# over the cwd, causing the agent to be pinned to the old workspace rather than
# the new one. We unset it here (for the child process only) so the agent
# starts in the new workspace.
if [[ "$paseo_run" == true ]] && command -v paseo >/dev/null; then
    (
        cd "$dir"
        env -u PASEO_WORKSPACE_ID paseo run hi --provider claude/opus \
            --thinking high --mode bypassPermissions --detach
    )
fi
