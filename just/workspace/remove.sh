#!/usr/bin/env bash
set -euo pipefail

# Remove a jj workspace and its colocated git worktree, safely. The jj analog
# of `worktree remove`: forgets the workspace, deletes the worktree + directory,
# and preserves any un-integrated commits — jj never drops committed work, so
# they survive as anonymous heads (`jj log`) unless you pass --force.
# Usage: just -g workspace remove <dir> [--force]

dir="$1"
shift
args="$*"

# --force/-f: remove even a dirty worktree, and abandon un-integrated commits.
force=false
if [[ " $args " == *" --force "* || " $args " == *" -f "* ]]; then
    force=true
fi

# Workspace name follows the `workspace add` convention: the path basename.
name="$(basename "$dir")"
if ! jj workspace list | grep -q "^$name:"; then
    echo "workspace remove: no jj workspace named '$name'." >&2
    echo "Known workspaces:" >&2
    jj workspace list >&2
    exit 1
fi

# Refuse to remove the workspace we're standing in — it can't delete its own
# directory, and losing the primary would orphan the repo. Run from another
# workspace (usually the main one).
tgt="$(cd "$dir" 2>/dev/null && pwd -P || true)"
if [[ -n "$tgt" && "$tgt" == "$(jj root)" ]]; then
    echo "workspace remove: refusing to remove the current workspace ($tgt)." >&2
    echo "Run this from the main workspace." >&2
    exit 1
fi

# Guard uncommitted work. A colocated workspace exposes its working-copy (@)
# changes as a dirty git tree (git HEAD tracks @-), so a non-empty @ reads as
# dirty. Refuse rather than discard it, unless --force. We check here instead
# of leaning on `jj workspace forget --cleanup`, which forgets the workspace
# regardless and merely skips the worktree — leaving a half-removed state.
dirty="$(git -C "$dir" status --porcelain 2>/dev/null || true)"
if [[ "$force" != true && -n "$dirty" ]]; then
    echo "workspace remove: '$dir' has uncommitted changes." >&2
    echo "Commit them (jj commit), or pass --force to discard it." >&2
    exit 1
fi

# Resolve the integration baseline (jj's trunk() ~ git origin/HEAD). trunk()
# degrades to root() without a remote, which would count shared commits as
# un-integrated; fall back to the local default bookmark in that case.
nonempty() { jj log --no-pager --no-graph -r "$1" -T '"x"' 2>/dev/null; }
base='trunk()'
if [[ -z "$(nonempty 'trunk() ~ root()')" ]]; then
    base='root()'
    for bm in main master; do
        if [[ -n "$(nonempty "present($bm)")" ]]; then
            base="$bm"
            break
        fi
    done
fi

# Capture the workspace's un-integrated, non-empty commits before forgetting.
# jj keeps them as anonymous heads afterward (work is never lost); we report
# them, or abandon them with --force. Their change IDs survive the forget.
leftover="$(jj log --no-pager --no-graph -r "${base}..${name}@ ~ empty()" \
    -T 'change_id.short() ++ "\n"' 2>/dev/null | grep -v '^$' || true)"
count=0
[[ -n "$leftover" ]] && count="$(printf '%s\n' "$leftover" | wc -l | tr -d ' ')"

# Forget the workspace and remove its git worktree + directory. The tree is
# clean here (guarded above) unless --force, which we pass through so a dirty
# worktree is removed too.
if [[ "$force" == true ]]; then
    jj workspace forget "$name" --cleanup --force
else
    jj workspace forget "$name" --cleanup
fi

# Resolve the workspace's bookmark (created by workspace add). It follows the
# same path derivation as workspace add — namespaced under worktrees/, not
# the basename workspace name — and is empty if no such bookmark exists.
if [[ "$dir" == *"worktrees/"* ]]; then
    bookmark="${dir#*worktrees/}"
else
    bookmark="$(basename "$dir")"
fi
[[ -n "$(nonempty "present($bookmark)")" ]] || bookmark=""

# Handle the bookmark and preserved commits, mirroring worktree remove's
# branch handling. Delete the bookmark and drop the commits when the work is
# integrated (count 0) or forced; otherwise keep both and report.
if [[ "$count" -eq 0 ]]; then
    [[ -n "$bookmark" ]] && jj bookmark delete "$bookmark"
    echo "Removed workspace '$name' at $dir${bookmark:+ and deleted bookmark '$bookmark'}"
elif [[ "$force" == true ]]; then
    [[ -n "$bookmark" ]] && jj bookmark delete "$bookmark"
    # shellcheck disable=SC2086
    jj abandon $leftover
    echo "Removed workspace '$name' at $dir and abandoned $count un-integrated commit(s)${bookmark:+, deleted bookmark '$bookmark'}"
else
    ids="$(printf '%s ' $leftover)"
    echo "Removed workspace '$name' at $dir${bookmark:+ (kept bookmark '$bookmark')}"
    echo "Kept $count un-integrated commit(s) as anonymous heads: ${ids}"
    echo "Integrate: jj rebase -r <id> -d <dest>   Discard: jj abandon ${ids}"
fi
