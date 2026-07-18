---
name: jj-coedit
description: >-
  Make jj changes in a shared working copy while the user concurrently reviews
  or edits the stack. Use when the user invokes jj co-edit mode, asks Codex to
  keep `@` parked, requests routing edits or hunks to their home commits with
  jj-hunk-tool, or says "route" while sharing the checkout. Never move the
  checkout or run `jj edit` without an explicit exclusive lock.
---

# jj Co-edit Mode

Work in the same jj stack and **shared working copy** as the user. The user is
reading and editing commits while parked at a specific change (`@`). Do not
move them off it.

Edit files directly even though each raw edit lands in `@`, often the
**wrong commit**. Route it afterward to its home commit with
`jj-hunk-tool`, which moves hunks between commits without checking anything out.
Leave `@` clean of your changes before handing back so the user can keep
reviewing and editing undisturbed.

Because you can always route afterward, order and who-touches-what don't
matter — no need to ask how to split or sequence the work; just make the edit
and route it home.

Combine this skill with `queue-mode` when the user queues fixes. Make and route
those fixes while the user edits the same tree; do not rely on receiving
replies.

## #1 RULE: NEVER MOVE THE CHECKOUT

`@` is where the user is reading and making fixups. Moving it changes files
underneath them during review. **Do not run any command that repoints, replaces,
or abandons `@`:**

- `jj edit <rev>` — forbidden unless the user explicitly hands you an
  exclusive working-copy lock to resolve conflicts (see
  [Conflicts](#conflicts)).
- `jj new`, `jj checkout`, `jj co`
- `jj abandon @`, `jj squash` with no `--from` (defaults to squashing `@` away)
- `jj undo`, `jj op restore`, `jj op undo` — the op log is shared across all
  workspaces, and `jj undo` inverts the *latest* op, likely someone else's —
  these can revert the user's live work, not just yours. Do not use them
  unless explicitly asked; to undo your own work, `jj op revert <op-id>` your
  specific op.

Read-only jj commands are always fine (`jj log`, `jj diff`, `jj show`,
`jj file show -r <rev>`, `jj-hunk-tool hunks -r <rev>`) — read any commit
without checking it out. You never need `jj edit` to look.

## The loop

For each requested change:

1. **Edit the working-copy files** directly. The tree shows `@`'s cumulative
   state — all ancestors up to `@`.
2. **List your hunks:** `jj-hunk-tool hunks`. Identify the exact hunk IDs of the
   edit you just made — nothing else (see below).
3. **Pick the home commit** by change ID (`jj log`, blame, or
   `jj-hunk-tool absorb --dry-run` to see routing). Change IDs are stable across
   rewrites — target by change ID, never commit hash, since the user may
   rewrite commits concurrently.
4. **Move just those hunks** into the home commit:

   ```sh
   # Explicit target:
   jj-hunk-tool squash <hunk-id>... --into <change-id>

   # Or let blame route them (pass IDs so it only touches YOUR hunks):
   jj-hunk-tool absorb <hunk-id>...
   ```

5. **Confirm `@` is stable:** `jj log` shows `@` at the same change; `jj diff`
   shows `@` free of your edit (only the user's in-progress work may remain).

Route your changes before you hand control back — never go idle with them
sitting in `@`, where they commingle with the user's fixups.
Until then, batch freely: hunks bound for the same commit go in one
`squash --into`, a mixed batch in one `absorb <ids>` — fewer calls, fewer
descendant-rebases. Moving a hunk into an ancestor leaves `@`'s tree unchanged,
so run CI whenever; it sees the same files either way.

## The bare "route" command

When the user says **"route"** with little or no other context, distribute
everything currently in `@` to its home commit in the stack. Reason through
each hunk yourself and `squash --into` its home commit by change ID — don't
lean on `jj-hunk-tool absorb`'s automated blame to place them.

This overrides "only ever move YOUR hunks" below: route moves all of `@`,
including the user's hand-written edits. Anything you cannot confidently
place, or that belongs in `@` itself, leave and tell the user.

## Only ever move YOUR hunks

The user is editing the same working copy, so `@` may hold their uncommitted
work alongside yours. **Never sweep their hunks into another commit.**

- Never run a bare `jj-hunk-tool absorb` or `jj-hunk-tool squash --from @` with
  no hunk IDs — that moves *everything*, including the user's work.
- Always select the specific hunk IDs you just wrote. You know what you changed;
  if `jj-hunk-tool hunks` shows changes you do not recognize, they belong to
  the user. Leave them in `@`, untouched.
- If you genuinely cannot distinguish your hunk from the user's, **stop and
  ask.** Do not guess and risk moving the user's work.

## When the change belongs in `@`

If a change genuinely belongs in `@` itself (where the user is parked), leave
it there and tell the user. Since you may both be in that file, expect the
occasional collision.

## We're editing the same files at once

Expect the occasional failed or clobbered edit — the user or another AI may be
editing the same file at the same moment. Do not let it stop you.

- If your edit didn't apply, or got overwritten alongside other changes to the
  file, just redo it.
- If code you wrote was changed but not reverted, keep the user's or AI
  co-editor's version — usually a cleanup or style fix to respect.
- If your work was cleanly reverted with no other change to the file, the user
  or an AI co-editor likely rejected that change; raise it if you think
  that's a mistake.

## Conflicts

Routing a hunk into an ancestor rebases its descendants (including `@`), and jj
records any conflict in the tree instead of stopping. So after a move, check
`jj log` for conflict markers, and resolve by editing the files — not by
undoing. If a conflict is ambiguous or you are stuck, leave it and tell the
user.

Some conflicts can't be resolved from `@` at all: when several stacked commits
touch one file, a higher commit's version **masks** the lower ones', so `@`
never shows what each ancestor actually needs, and routing a partial fix down
just nests the conflict or bakes literal marker text into a commit.
Resolving these conflicts needs a bottom-up `jj edit` pass, which moves `@`.
Often you can avoid disturbing anyone: create your own side workspace and do
the bottom-up pass there (use the `jj-surgery` skill) — the shared `@` never
moves. Afterward re-sync the shared workspace's git view: check that
`git rev-parse HEAD` there matches `@-`'s commit, and `git reset <that
commit>` if not — jj doesn't always re-export a peer workspace's git HEAD,
and git tools (vgit) otherwise keep reading the pre-rewrite commits. If that is impractical, stop and ask for an exclusive working-copy lock.
Once the user confirms that their work and any other agents are parked, you may
`jj edit` each commit directly to fix the conflicts. Work bottom-up and fully
resolve each commit before moving to the next one up — no markers left,
`jj resolve --list` clean,
and it builds; leaving a conflict behind just cascades new ones into its
descendants. `jj new` back to the tip when done.

## Carry things forward

Do not bury questions, judgment calls, or important notes in a reply the user
may never see. Retain them and surface the accumulated notes once a genuine
follow-up shows that the user has returned.
