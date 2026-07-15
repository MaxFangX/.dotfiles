---
description: Make jj changes in the shared working copy while I review and edit the stack concurrently. Keep @ where it is; route every edit to its home commit with jj-hunk-tool. NEVER run `jj edit`.
---

# jj Co-edit Mode

We're both working the same jj stack at once. I'm reading and editing commits;
you're making changes I've asked for. You edit the **shared working copy** I'm
looking at. The catch: I'm parked at a specific change (`@`) to review it, and
you must not move me off it.

The deal is simple. You may edit any file, but the raw edit lands in `@` —
often the **wrong commit**. That's fine — route it to its home commit with
`jj-hunk-tool`, which moves hunks between commits without checking anything out.
Leave `@` clean of your changes before you hand back, and I keep reviewing and
editing undisturbed.

Because you can always route afterward, order and who-touches-what don't
matter — no need to ask how to split or sequence the work; just make the edit
and route it home.

This mode combines with [queue mode](queue-mode.md): I'll queue fixes for you
to make and route into place while I edit by hand, both of us in the same tree.
I'll often reply, but don't always expect me to.

## #1 RULE: NEVER MOVE THE CHECKOUT

`@` is where I'm reading and making my own fixups. Moving it yanks the files out
from under me mid-review. **Do not run any command that repoints, replaces, or
abandons `@`:**

- `jj edit <rev>` — the cardinal sin here. Forbidden unless I've explicitly
  handed you an exclusive working-copy lock to resolve conflicts (see
  [Conflicts](#conflicts)).
- `jj new`, `jj checkout`, `jj co`
- `jj abandon @`, `jj squash` with no `--from` (defaults to squashing `@` away)
- `jj undo`, `jj op restore`, `jj op undo` — these can also revert *my* live
  work, not just yours. Forbidden unless I explicitly ask.

Read-only jj commands are always fine (`jj log`, `jj diff`, `jj show`,
`jj file show -r <rev>`, `jj-hunk-tool hunks -r <rev>`) — read any commit
without checking it out. You never need `jj edit` to look.

## The loop

For each change I ask for:

1. **Edit the working-copy files** directly. The tree shows `@`'s cumulative
   state — all ancestors up to `@`.
2. **List your hunks:** `jj-hunk-tool hunks`. Identify the exact hunk IDs of the
   edit you just made — nothing else (see below).
3. **Pick the home commit** by change ID (`jj log`, blame, or
   `jj-hunk-tool absorb --dry-run` to see routing). Change IDs are stable across
   rewrites — target by change ID, never commit hash, since I may be rewriting
   commits as we go.
4. **Move just those hunks** into the home commit:

   ```sh
   # Explicit target:
   jj-hunk-tool squash <hunk-id>... --into <change-id>

   # Or let blame route them (pass IDs so it only touches YOUR hunks):
   jj-hunk-tool absorb <hunk-id>...
   ```

5. **Confirm `@` is stable:** `jj log` shows `@` at the same change; `jj diff`
   shows `@` free of your edit (only my in-progress work, if any, remains).

Route your changes before you hand control back — never go idle with them
sitting in `@`, where they commingle with my fixups and get hard to tell apart.
Until then, batch freely: hunks bound for the same commit go in one
`squash --into`, a mixed batch in one `absorb <ids>` — fewer calls, fewer
descendant-rebases. Moving a hunk into an ancestor leaves `@`'s tree unchanged,
so run CI whenever; it sees the same files either way.

## The bare "route" command

When I say **"route"** with little or no other context, I mean: distribute
everything currently in `@` to its home commit in the stack. Reason through
each hunk yourself and `squash --into` its home commit by change ID — don't
lean on `jj-hunk-tool absorb`'s automated blame to place them.

This overrides "only ever move YOUR hunks" below: route moves all of `@`, my
hand-written edits included — that's the point. Anything you can't confidently
place, or that belongs in `@` itself, leave and tell me.

## Only ever move YOUR hunks

I'm editing the same working copy you are, so `@` may hold my uncommitted work
alongside yours. **Never sweep up my hunks into another commit.**

- Never run a bare `jj-hunk-tool absorb` or `jj-hunk-tool squash --from @` with
  no hunk IDs — that moves *everything*, mine included.
- Always select the specific hunk IDs you just wrote. You know what you changed;
  if `jj-hunk-tool hunks` shows changes you don't recognize, they're mine —
  leave them in `@`, untouched.
- If you genuinely can't tell your hunk from mine (e.g. we edited overlapping
  lines), **stop and ask.** Don't guess and risk moving my work.

## When the change belongs in `@`

If a change genuinely belongs in `@` itself (the change I'm parked on), leave it
there and tell me — and since we're probably both in that file, expect the
occasional collision (see below).

## We're editing the same files at once

Expect the occasional failed or clobbered edit — I or another AI may be editing
the same file you are, at the same moment. That's fine; don't let it stop you.

- If your edit didn't apply, or got overwritten alongside other changes to the
  file, just redo it.
- If code you wrote was changed but not reverted, keep my (or the AI
  co-editor's) version — usually a cleanup or style fix to respect.
- If your work was cleanly reverted with no other change to the file, I (or an
  AI co-editor) likely rejected that change; raise it in chat if you think
  that's a mistake.

## Conflicts

Routing a hunk into an ancestor rebases its descendants (including `@`), and jj
records any conflict in the tree instead of stopping. So after a move, check
`jj log` for conflict markers, and resolve by editing the files — not by
undoing. If a conflict is ambiguous or you're stuck, leave it and tell me.

Some conflicts can't be resolved from `@` at all: when several stacked commits
touch one file, a higher commit's version **masks** the lower ones', so `@`
never shows what each ancestor actually needs, and routing a partial fix down
just nests the conflict or bakes literal marker text into a commit.
Resolving these conflicts needs a bottom-up `jj edit` pass, which moves `@`.
Often you can avoid disturbing anyone: create your own side workspace and do
the bottom-up pass there (see the jj-surgery skill) — the shared `@` never
moves. If that's impractical, stop and ask me for an exclusive working-copy lock
(I'll stop my work and park any other agent's work). Once I've confirmed that
you have ownership over the working copy, you are free to `jj edit` each commit
directly to fix the conflicts. Work bottom-up and fully resolve each commit
before moving to the next one up — no markers left, `jj resolve --list` clean,
and it builds; leaving a conflict behind just cascades new ones into its
descendants. `jj new` back to the tip when done.

## Carry things forward

Because I may not be reading in real time, don't bury questions, judgment calls,
or anything I should know in a reply I may never see. Hold them and surface the
accumulated notes once it's clear I'm back in the chat.
