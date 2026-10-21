---
name: jj-cleanup
description: >-
  Tidy a jj repo's bookkeeping: fetch and fast-forward master, rebase parked
  working copies onto it, re-attach git HEAD, forget workspaces whose
  directory is gone, and report what needs a decision. Use when the user
  asks for a jj cleanup or tidy. "deep" extends it to every workspace,
  retiring finished ones and abandoning stray empty heads.
---

# jj cleanup

First, read the /jj skill. Its op-log and co-edit rules hold throughout.

Steps 1–5 and 7 move bookmarks, git refs, and empty commits, never file
content, so they need no confirmation, and `jj op revert` undoes the jj
side. Anything that needs a decision is reported, not fixed.

## Default

Steps 2 and 3 run per workspace, here and in `default`. Another
workspace's `@` is `<name>@`, and its git commands run in its directory.

1. `jj git fetch`. A tracked `master` not moved locally fast-forwards on
   its own. If it comes back conflicted, report and stop.
2. Pull. Where `<name>@` is empty, undescribed, and parked on the commit
   `master` pointed at before the fetch, `jj rebase -r <name>@ -o master`,
   then run `jj workspace update-stale` there and read its output. This
   moves a checkout, which /jj forbids for one you don't own; invoking
   this skill is the user's permission for theirs, so skip workspaces that
   belong to other agents. A non-empty `@` stays put; say so, after
   ruling out a phantom. A `git pull`/`checkout` that rewrote the files,
   followed by a `git reset` back to the old HEAD, leaves jj snapshotting
   master's own content as changes. So before calling an undescribed diff
   work, `jj diff --from <name>@ --to <commit> --stat` against each commit
   in that workspace's `git reflog`; a byte-identical match means `@`
   holds nothing of its own: `jj new master` and abandon it, under the
   same ownership rule as the rebase.
3. Re-attach git HEAD per /jj's end-of-turn rule, to the workspace's
   branch (usually named for the workspace; skip if it has none).
4. `jj workspace forget` each record whose root `jj workspace list` cannot
   resolve (it prints no path) and whose `@` is empty, then
   `git worktree prune`.
5. Report, one line each: `master` ahead of its remote, conflicted stacks
   (`jj log -r 'roots(conflicts())'`), divergent changes, working copies
   holding undescribed changes (name the files, not a guessed project),
   phantoms dropped in step 2, and anything skipped above.

## Deep

"deep" widens steps 2 and 3 to every workspace and adds two steps. Run
them in the order 1, 6, 2–4, 7, 5: retiring must precede the rebase that
would move a finished workspace off its branch, and the report comes last.

6. Retire finished workspaces: `<name>@` is empty and its parent carries a
   branch bookmark that is an ancestor of `master`. `default` and this
   workspace are never candidates. Removal also deletes ignored files such
   as `.env` and `tmp/`, which often holds plan docs and data worth keeping,
   so list the candidates with what each one's `tmp/` holds and ask once
   for the batch, then `jj workspace forget --cleanup <name>` for each. Its
   `git worktree remove` refuses a dirty worktree; report those.
7. Abandon stray empty heads. `jj workspace forget` already abandons the
   empty `@` it drops, so these come from elsewhere:

   ```sh
   jj abandon -r 'heads(mutable()) & empty() & description(exact:"")
     & ~bookmarks() & ~working_copies()'
   ```
