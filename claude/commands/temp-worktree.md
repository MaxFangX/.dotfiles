---
description: Make changes and absorb them into history from a separate worktree so I can keep working in mine; you own it and drive its git.
---

# Temp worktree mode

I want you to make changes and **absorb them into the commit history** — fixups,
splits, reorders, rebases — while I keep working in my own worktree. It's that
absorption, not the editing, that rewrites history and resets the working tree,
which would clobber my live edits. Do it all in a **throwaway worktree on its own
branch**, never in mine.

Unlike [rebase-review](rebase-review.md), where I drive git, here **you drive git
yourself** — I'm not in this worktree, so nothing of mine is at risk. Commit,
rebase, reset, continue freely.

## Where to put it

The worktree needs its **own branch** (a branch checks out in only one worktree
at a time), snapshotting the current feature tip.

- Prefer `~/lexe/worktrees/ai/<name>` if `~/lexe/worktrees/` exists.
- Else somewhere parallel to my worktree, e.g. under `~/.paseo/worktrees/`.

```
git worktree add <path> -b <work-branch> <feature-tip>
```

Record the **fork point** (feature tip at creation) — needed to reconcile.

## Division of labor

- I keep working the feature branch in my worktree. **Leave it alone** — never
  edit a path under it.
- You do all the work on `<work-branch>` — make the changes and absorb them into
  commits. We share one `.git`, so you see my feature-branch commits live — no
  fetch.
- Edits and `just` CI run from the temp worktree via absolute paths / `cd`.

## Reconciling back into the feature branch

**Our histories may have diverged — don't assume a clean fast-forward.** While
you work I may also be editing the feature branch, sometimes rewriting existing
commits (my own rebase-review) rather than only adding on top, which can leave us
with divergent rewrites of overlapping commits.

**And a tip diff won't necessarily show it.** Rewriting on either side can leave
the tree identical while commits differ (a fixup/split/reorder/message edit
changes no net content), so an empty `git diff <feature> <work-branch>` proves
nothing — adopting your branch on it could silently drop my commit-level work.
**Compare commit-by-commit (`git range-diff`), never by tree-sums.**

1. `git status` in my worktree dirty? Stop and tell me.

2. `git rev-parse <feature>` == `<fork-point>`? Then I committed nothing since you
   forked — adopt yours wholesale: `git reset --hard <work-branch>` from my
   worktree, done. Otherwise keep going.

3. `git merge-base --is-ancestor <fork-point> <feature>`?
   - **Succeeds** — I only appended: replay my commits onto your work via a
     scratch branch, `git rebase --onto <work-branch> <fork-point> <feature>`,
     then I adopt it.
   - **Fails** — I rewrote existing commits; your branch is stale. Go to 4.

4. My branch is the source of truth — never reset it onto your stale one. Read
   the divergence commit-by-commit:

   ```
   BASE=$(git merge-base <feature> <work-branch>)
   git range-diff $BASE..<feature> $BASE..<work-branch>
   ```

   Re-cut a branch from my current feature tip and redo your work there, guided by
   the range-diff and your record of what you changed. Structural changes
   (fold/split/reorder) usually redo cleanly; content edits must be re-applied to
   the matching commits. Expect conflicts; resolve by editing, never with
   `--abort`/`--skip`/a discarding reset. If genuinely ambiguous, stop and ask.

## Cleanup

Once merged, tear down the worktree and branch without asking (you'll recreate
them next invocation): `git worktree remove <path>`, then
`git branch -D <work-branch>`.
