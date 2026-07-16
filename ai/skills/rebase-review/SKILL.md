---
name: rebase-review
description: >-
  Perform deep concurrent code review and working-tree fixups while the user
  drives an interactive Git rebase. Use when the user invokes rebase review
  mode, is approving hunks during a rebase, or asks the agent to edit alongside
  a human-controlled rebase without staging, committing, continuing, skipping,
  or aborting it.
---

# Rebase review mode

Perform a deep, interactive review and fixup of an existing **stack of
commits**. The user drives an **interactive rebase** so each commit can be
refined in place instead of absorbing every fix downward from the stack tip.

Combine this skill with `queue-mode` when the user queues feedback. Expect the
user to make small edits in the same tree and do not rely on receiving replies.

## The user's loop

Use this loop to understand the current state:

1. The user creates a backup branch, then starts `git rebase -i` onto the base.
2. Already-approved commits at the bottom of the stack stay `pick`.
3. The user marks the commit under review, and sometimes every commit above it,
   as `edit` so the rebase stops there.
4. The user soft-resets that commit and approves hunks by staging them.
   **Staged means approved by the user.**
5. The user queues discovered feedback while continuing to edit.
6. Once every hunk is approved, the user recreates the commit with its original
   message and continues the rebase.
7. Repeat at each `edit` stop until the whole stack is approved and the PR is
   ready for review.

## #1 RULE: NEVER ABORT THE REBASE

This is the most important instruction in this document. **Do not, under any
circumstances, run `git rebase --abort`.**

All in-progress fixes live only in the working tree and rebase state. Aborting
throws away both your edits and the user's edits. The backup branch contains
the *pre-rebase* state and **none** of these fixes, so it will not help.

The same catastrophe applies to anything else that discards worktree changes or
rebase state — treat all of these as equally forbidden:

- `git rebase --abort` / `--skip`
- `git reset --hard`, `git reset` to another commit
- `git checkout -- .` / `git checkout <ref> -- <path>`
- `git restore` over uncommitted changes
- `git stash` (it removes the user's in-progress edits from the tree)

Do not run any of these unless the user explicitly and unambiguously asks.

If you are ever tempted to "get back to a clean state," STOP. A messy,
mid-conflict, in-progress rebase is expected and preserves the correct
foundational assumptions. Rebase difficulties are no excuse to discard it.

## Let the user drive Git

Let the user own every Git state transition. Edit files in the working tree in
response to feedback and do nothing more unless explicitly asked.

Do not do any of the following unless the user explicitly says so:

- **Stage (`git add`)** — staging is the user's approval signal. Touching the
  index corrupts their review of which hunks are done.
- Commit or amend.
- `git rebase --continue`, `--skip`, and (see above) NEVER `--abort`.
- Reset, restore, checkout, stash, or anything else that moves HEAD or discards
  worktree changes.

Read-only git commands are always fine.

## Conflicts are expected — resolve, never escape

Expect conflicts while replaying fixes over the stack.

- When asked to resolve a conflict, resolve it by **editing the files**.
  Never resolve it by aborting or skipping.
- If a conflict is genuinely ambiguous, or you get stuck, stop and tell the
  user. Leave the rebase exactly as it is for them to handle. Do not try
  to unblock yourself with any destructive command.

## We're editing the same tree at once

Expect occasional failed edits and overwritten work — the user may be editing
the same file at the same time.

- If code you wrote was changed but not reverted, keep the user's change; it is
  usually a cleanup or style correction to respect.
- If your edit didn't apply or got clobbered alongside other changes to the same
  file, that's fine — just redo it.
- If your work was cleanly reverted with no other change to the file, the user
  probably rejected that approach. Point it out if you think that was a
  mistake.

## Carry things forward

Do not bury questions, judgment calls, or important notes in a response the
user may never read. Retain them and surface the accumulated notes once a
genuine follow-up shows that the user has returned.
