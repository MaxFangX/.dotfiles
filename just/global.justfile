# Global justfile — machine-wide recipes, run from anywhere with `just -g <recipe>`.
# Home-manager symlinks this to ~/.config/just/justfile (see home/mods/core.nix).

# Create a git worktree for AI development. Best run from the main worktree.
worktree-add dir:
    #!/usr/bin/env bash
    set -euo pipefail

    dir="{{ dir }}"

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

# Remove a git worktree and its associated branch.
worktree-remove dir *args:
    #!/usr/bin/env bash
    set -euo pipefail

    dir="{{ dir }}"
    args="{{ args }}"

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
    default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
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

# Make a worktree the primary (main) worktree, carrying colocated jj along. Defaults to cwd.
worktree-set-primary dir=".":
    #!/usr/bin/env bash
    set -euo pipefail

    # Exactly one worktree owns the real `.git` directory (git calls it the
    # "main" worktree; we say "primary"); the rest hold a `.git` *file* pointing
    # into it. Jujutsu only colocates (`jj git init --colocate`) in the primary
    # worktree — it refuses inside a linked one. So to use jj in a given
    # worktree, that worktree must become primary. This promotes any worktree on
    # demand, demoting the current primary to a linked one.
    #
    # jj state is preserved: the colocated `.jj` moves as a unit next to `.git`,
    # and jj's git pointer (.jj/repo/store/git_target) is relative (../../../.git),
    # staying valid wherever the pair lands. The whole `.jj/repo` (every commit,
    # bookmark, conflict, and the operation log) moves by a single rename, so
    # committed jj history cannot be split or corrupted. git objects/refs move the
    # same way. Because a move only ever deletes the source after the destination
    # is complete, an interrupted run never loses data — rerun, or repair pointers
    # with `git worktree repair`.
    #
    # The one subtlety is jj's working copy (@): it's bound to a directory's files,
    # so once jj runs in the new main it snapshots THAT worktree's files into @.
    # Uncommitted work from the old main is NOT lost — it stays in the old main's
    # git working tree (now a linked worktree) and in the jj op log (`jj op log` /
    # `jj op restore`) — but @ tracks the new main going forward. Prefer promoting
    # from a clean-ish @. Also: using jj detaches the worktree's git HEAD (jj's
    # model); `git switch <branch>` to reattach before git-only work there. Don't
    # run jj in a worktree mid `git rebase/merge` — jj would reset HEAD and disrupt
    # it (this recipe itself uses `--ignore-working-copy` and won't).

    # Resolve to the worktree root, so a bare `just -g worktree-set-primary`
    # works from anywhere inside the worktree.
    target="$(git -C "{{ dir }}" rev-parse --show-toplevel)"

    # A worktree's per-worktree state (HEAD, index, in-progress merge/rebase, ...)
    # sits at the top of `.git` for the main worktree but inside
    # `.git/worktrees/<name>` for a linked one; everything else is shared.
    # Promoting therefore *swaps* which per-worktree bundle occupies the top level
    # — not just moving the directory. We identify per-worktree state by exclusion
    # (a denylist of shared/structural entries) rather than an allowlist, so ANY
    # per-worktree file git may create — REBASE_HEAD, AUTO_MERGE, sequencer/,
    # BISECT_*, future additions — travels intact and is never left behind to be
    # deleted with the emptied bundle.
    shared_top=(objects refs logs worktrees config hooks info description \
      packed-refs branches remotes shallow rr-cache common modules svn lfs \
      gc.pid gc.log fsmonitor--daemon commondir gitdir)

    # move_pwt SRC DST: move the per-worktree fileset from dir SRC to dir DST —
    # every top-level entry except the shared ones, then the per-worktree slices
    # of the (otherwise shared) logs/ and refs/ dirs.
    move_pwt() {
        local src="$1" dst="$2" path name s r
        mkdir -p "$dst"
        shopt -s dotglob nullglob
        for path in "$src"/*; do
            name="$(basename "$path")"
            for s in "${shared_top[@]}"; do [ "$name" = "$s" ] && continue 2; done
            mv "$path" "$dst/$name"
        done
        shopt -u dotglob nullglob
        [ -e "$src/logs/HEAD" ] && { mkdir -p "$dst/logs"; mv "$src/logs/HEAD" "$dst/logs/HEAD"; }
        for r in bisect worktree rewritten; do
            [ -e "$src/refs/$r" ] && { mkdir -p "$dst/refs"; mv "$src/refs/$r" "$dst/refs/$r"; }
        done
        return 0
    }

    # Resolve topology from the target. --git-common-dir is the shared repo
    # (== oldmain/.git); --git-dir is the target's own gitdir. They're equal iff
    # the target already *is* the main worktree.
    common="$(git -C "$target" rev-parse --path-format=absolute --git-common-dir)"
    gitdir="$(git -C "$target" rev-parse --path-format=absolute --git-dir)"
    if [ "$common" = "$gitdir" ]; then
        echo "$target is already the primary worktree; nothing to do."
        exit 0
    fi

    oldmain="$(dirname "$common")"
    tname="$(basename "$gitdir")"

    # Fresh admin name for the demoted old main (avoid colliding with an existing
    # worktrees/<name>).
    oldname="$(basename "$oldmain")"
    while [ -e "$common/worktrees/$oldname" ]; do oldname="${oldname}_"; done

    echo "Setting $target as the primary worktree (demoting $oldmain)..."

    # 1. Relocate the physical repo (and colocated .jj) into the target.
    rm -f "$target/.git"                        # drop target's linked pointer file
    mv "$common" "$target/.git"                 # target now owns the real .git dir
    [ -e "$oldmain/.jj" ] && mv "$oldmain/.jj" "$target/.jj"
    g="$target/.git"

    # 2. Demote old main: bundle its top-level per-worktree state under worktrees/<oldname>.
    move_pwt "$g" "$g/worktrees/$oldname"
    printf '../..\n'              > "$g/worktrees/$oldname/commondir"
    printf '%s\n' "$oldmain/.git" > "$g/worktrees/$oldname/gitdir"   # plain path
    printf 'gitdir: %s\n' "$g/worktrees/$oldname" > "$oldmain/.git"  # pointer file

    # 3. Promote target: lift its admin bundle up to the top level, drop the bundle.
    move_pwt "$g/worktrees/$tname" "$g"
    rm -rf "$g/worktrees/$tname"

    # 4. Repair every worktree's two-way pointers (absolute paths moved with the repo).
    git -C "$target" worktree repair >/dev/null 2>&1 || true
    while IFS= read -r wt; do
        [ -n "$wt" ] && git -C "$target" worktree repair "$wt" >/dev/null 2>&1 || true
    done < <(git -C "$target" worktree list --porcelain | awk '/^worktree /{print $2}')

    echo "Done. Primary worktree is now $target"

    # Colocated jj followed the move. Warn if standalone `jj workspace add`
    # workspaces exist: each holds a *relative* pointer (.jj/repo -> <oldmain>/.jj/repo)
    # that now dangles. jj doesn't record their filesystem paths, so we can't fix
    # them automatically — repoint each one's `.jj/repo` at <newmain>/.jj/repo.
    if command -v jj >/dev/null && [ -d "$target/.jj" ]; then
        # --ignore-working-copy: read the view without snapshotting or touching
        # git HEAD, so we never disturb an in-progress merge/rebase in the new main.
        nws="$(jj --ignore-working-copy -R "$target" workspace list 2>/dev/null | wc -l | tr -d ' ')"
        if [ "${nws:-0}" -gt 1 ]; then
            echo
            echo "warning: repo has $nws jj workspaces; any from 'jj workspace add' now"
            echo "         point at the old main. Repoint each: set <ws>/.jj/repo to the"
            echo "         relative path of $target/.jj/repo"
        fi
    fi
