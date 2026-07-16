---
name: temp-worktree
description: >-
  Make changes and rewrite or absorb them into Git history from an isolated
  temporary worktree while the user continues in the original worktree. Use
  when the user invokes temp worktree mode or asks the agent to own a throwaway
  worktree for fixups, splits, reorders, or rebases and reconcile the result
  safely afterward.
---

# Temp worktree mode

Make changes and **absorb them into commit history**, including fixups, splits,
and rebases, while the user keeps working in the original worktree. Because
history rewrites reset the working tree, perform all work in a **throwaway
worktree on its own branch**, never in the user's worktree.

Unlike `rebase-review`, where the user drives Git, **drive Git yourself** in the
temporary worktree. Commit, rebase, reset, and continue freely there.

## Where to put it

The worktree needs its **own branch** (a branch checks out in only one worktree
at a time), snapshotting the current feature tip.

- Prefer `~/lexe/worktrees/ai/<name>` if `~/lexe/worktrees/` exists.
- Otherwise, use a path parallel to the user's worktree, such as
  `~/.paseo/worktrees/`.

```
git worktree add <path> -b <work-branch> <feature-tip>
```

Record the **fork point** (feature tip at creation) — needed to reconcile.

## Division of labor

- The user keeps working on the feature branch in the original worktree.
  **Leave it alone** and never edit a path under it.
- Do all work on `<work-branch>` and absorb the changes into commits. The
  worktrees share one `.git`, so the user's feature-branch commits appear live
  without a fetch.
- Edits and `just` CI run from the temp worktree via absolute paths / `cd`.

## Reconciling back into the feature branch

**The histories may diverge; do not assume a clean fast-forward.** The user may
also edit the feature branch, sometimes rewriting existing commits
with `rebase-review` rather than only appending commits. This can produce
divergent rewrites of overlapping commits.

**And a tip diff won't necessarily show it.** Rewriting on either side can leave
the tree identical while commits differ (a fixup/split/reorder/message edit
changes no net content), so an empty `git diff <feature> <work-branch>` proves
nothing — adopting your branch on it could silently drop the user's work.
**Compare commit-by-commit (`git range-diff`), never by tree-sums.**

1. If `git status` in the user's worktree is dirty, stop and tell the user.

2. If `git rev-parse <feature>` equals `<fork-point>`, the user committed
   nothing after the fork. Adopt the work branch wholesale with
   `git reset --hard <work-branch>` from the user's worktree. Otherwise,
   continue.

3. `git merge-base --is-ancestor <fork-point> <feature>`?
   - **Succeeds** — the user only appended commits. Replay them onto your work
     via a scratch branch with
     `git rebase --onto <work-branch> <fork-point> <feature>`, then let the user
     adopt it.
   - **Fails** — the user rewrote existing commits; your branch is stale. Go
     to 4.

4. Treat the user's branch as the source of truth. Never reset it onto your
   stale branch. Read the divergence commit-by-commit:

   ```
   BASE=$(git merge-base <feature> <work-branch>)
   git range-diff $BASE..<feature> $BASE..<work-branch>
   ```

   Re-cut a branch from the user's current feature tip and redo your work there,
   guided by the range-diff and your record of what you changed. Structural
   changes usually redo cleanly; content edits must be re-applied to the
   matching commits. Expect conflicts; resolve by editing, never with
   `--abort`/`--skip`/a discarding reset. If genuinely ambiguous, stop and ask.

## Cleanup

Once merged, tear down the worktree and branch without asking; recreate them on
the next invocation: `git worktree remove <path>`, then
`git branch -D <work-branch>`.
