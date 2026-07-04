---
description: Deep, concurrent code review and fixup over a stack of commits while I drive an interactive rebase. You MUST NOT abort the rebase.
---

# Rebase review mode

We're doing a deep, interactive review and fixup of an existing **stack of
commits**. Instead of reviewing from a checkout at the top of the stack — where
every fix then has to be laboriously absorbed back down into the right commit,
leaving dead time while I wait — I drive an **interactive rebase** and we refine
each commit in place.

This mode combines with queue mode. I'll queue feedback for you to fix
asynchronously while I make my own small edits by hand, both of us working the
same tree at once. I will often reply, but don't always expect me to.

## The loop I'm running

So you always know where we are:

1. I create a backup branch, then start `git rebase -i` onto the base.
2. Commits at the bottom of the stack that I've already approved stay `pick`.
3. The commit I'm reviewing (and sometimes every commit above it) I mark `edit`,
   so the rebase stops there.
4. I soft-reset that commit and use my hunk-staging workflow to "approve" hunks
   one at a time. **Staged == approved by me.**
5. As I review, I discover feedback. I queue it to you to fix while I keep
   making my own edits.
6. Once every hunk is approved, I recreate the commit with its original message
   via `git commit --reuse-message=ORIG_HEAD`, then `git rebase --continue`.
7. Repeat at each `edit` stop until the whole stack is approved and the PR is
   ready for review.

## #1 RULE: NEVER ABORT THE REBASE

This is the most important instruction in this document. **Do not, under any
circumstances, run `git rebase --abort`.**

All of our in-progress fixes live only in the working tree and the in-progress
rebase state. Aborting throws every one of them away — every edit you made and
every edit I made this session, gone. The backup branch is the *pre-rebase*
state; it contains **none** of the fixes we've made, so it will not save us.

The same catastrophe applies to anything else that discards worktree changes or
rebase state — treat all of these as equally forbidden:

- `git rebase --abort` / `--skip`
- `git reset --hard`, `git reset` to another commit
- `git checkout -- .` / `git checkout <ref> -- <path>`
- `git restore` over uncommitted changes
- `git stash` (it removes my in-progress edits from the tree)

Do not run any of these. Ever. Unless I explicitly and unambiguously ask.

If you are ever tempted to "get back to a clean state," STOP. A messy,
mid-conflict, in-progress rebase is exactly the state we want. It forces us to
always architect things with the correct foundational assumptions; rebase
difficulties are no excuse.

## Let me drive git

I own every git state transition in this loop. Your job is to edit files in the
working tree in response to my feedback — nothing more, unless I ask.

Specifically, do not do any of the following unless I explicitly say so:

- **Stage (`git add`)** — staging is *my* approval signal. Touching the index
  corrupts my review of which hunks are done.
- Commit or amend.
- `git rebase --continue`, `--skip`, and (see above) NEVER `--abort`.
- Reset, restore, checkout, stash, or anything else that moves HEAD or discards
  worktree changes.

Read-only git commands are always fine.

## Conflicts are expected — resolve, never escape

Replaying our fixes over the stack will often produce conflicts. That's normal.

- When I ask you to resolve a conflict, resolve it by **editing the files**.
  Never resolve it by aborting or skipping.
- If a conflict is genuinely ambiguous, or you get stuck, stop and tell me.
  Leave the rebase exactly as it is, mid-conflict, for me to handle. Do not try
  to unblock yourself with any destructive command.

## We're editing the same tree at once

Expect occasional failed edits and overwritten work — I may be editing the
same file you are, at the same time.

- If code you wrote was changed but not reverted, keep my change; it's usually a
  cleanup or style correction to respect.
- If your edit didn't apply or got clobbered alongside other changes to the same
  file, that's fine — just redo it.
- If your work was cleanly reverted with no other change to the file, I probably
  rejected that approach — point it out in our chat if you think that was a
  mistake.

## Carry things forward

Because I may not be reading along in real time, don't bury questions,
judgment-call decisions, or anything I should know in a response I may never
read. Hold onto them and surface the accumulated notes once it's clear I've
returned to the chat.
