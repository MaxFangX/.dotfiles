---
name: jj
description: >-
  Working in jj (Jujutsu) repos: everyday workflows, history surgery
  (splitting commits, inserting prefactors, propagating renames, rewriting
  intermediate commits), and co-editing a shared working copy — often in a
  live repo shared with a human or other agents. Use for any jj-based work.
  Saying "coedit" activates co-edit mode: keep the shared `@` parked, never
  move the checkout, and route edits to their home commits with
  jj-hunk-tool. Saying "route" asks to distribute `@`'s changes to their
  home commits in the stack.
---

# jj

Working skillfully in a jj repo, up to full history surgery: splits,
prefactors, renames that must read as if they "had always been that way".
Everything here leans on two jj facts: every rewrite auto-rebases all
descendants, and conflicts are recorded data, not stop-signs.

## Ground rules

- Target commits by **change ID**, never commit hash — hashes go stale after
  every rewrite, often mid-task under concurrency. Re-resolve any commit ID
  from a fresh `jj log` before each batch of work.
- No interactive anything: bare `jj split`, bare `jj diffedit`, any `-i` flag
  opens an editor and hangs forever. Use `jj split <paths> -m` or
  `jj-hunk-tool`. Pass `-m` to every command that sets a description — and
  watch for commands that set one *implicitly*: a path-limited `jj squash`
  that happens to empty its source merges the two descriptions in an editor.
  Pass `--use-destination-message` (or `-m`) to any squash that might empty
  the source.
- A jj command that silently never returns is almost always a hidden editor.
  Confirm with a stack sample of the hung pid (macOS: `sample <pid>`; look
  for `TextEditor::edit_str`). Later jj writes queue behind it; killing the
  hung processes is safe — an op either lands atomically or not at all, so
  check `jj op log` afterward to see what (if anything) applied.
- View diffs with `--git --no-pager`.
- The working copy snapshots **only when a jj command runs in that workspace**.
  After editing files with non-jj tools, run `jj status` to snapshot — until
  then the repo has not seen your edits: `conflicts()` is stale, descendants
  haven't rebased, and checks you run "against the repo" are lies.
- Every rewrite rebases all descendants, so batch: hunks bound for the same
  commit go in one command; unrelated edits to one commit go in one
  edit-then-snapshot cycle.
- Don't `jj abandon` an empty `@`; empty working copies are normal. When an
  operation empties `@`, jj may replace it with a fresh change ID at the same
  spot — harmless, but mention it if someone is parked there.

## Op log: shared, and how to undo

One op log spans all workspaces of a repo, so undo-family commands mutate
state shared with every workspace — even when each editor stays in their own.
Check `jj workspace list` first: if this is the repo's only workspace,
`jj undo` is probably fine; if there are several, assume concurrent editors
and touch only ops that are provably yours.

- **NEVER `jj op restore` to undo your own work** — it rewinds *every*
  workspace, clobbering the human's and every peer agent's concurrent work.
- **`jj undo` is a trap under concurrency**: it inverts the *latest* op in
  the shared log, which is likely a peer's op that landed after yours — and a
  second `jj undo` doesn't cancel the first, it walks one op further back,
  peeling off peers' ops one by one. To undo your own work, find your op in
  `jj op log` and `jj op revert <op-id>` that specific op. If you did undo a
  peer's op, re-apply it by `jj op revert`ing the undo op itself.
- `jj op log` is the forensics tool. When state looks wrong, read the last
  ~10 ops *before* concluding breakage — often the human or a peer agent
  squashed or renamed under you, in which case keep their change and adapt
  yours.
- Recover files from the past without touching the op timeline:
  `jj --at-op=<op> file show`, or `jj restore --from <old-commit-id>` —
  hidden commits stay addressable by commit ID for diff and restore.
- That is also how to keep a pre-surgery backup: record the tip's commit ID.
  Do **not** pin a backup bookmark to the old commit — a bookmark keeps the
  whole old lineage visible, turning every rewritten change divergent.

## Operating modes

Who owns the main checkout determines how you work:

- **Co-edit** — activated when the user says "coedit": the human owns `@`,
  and everyone — human and agents alike — edits the same working copy.
  Follow the full contract in
  [Co-edit mode](#co-edit-mode). Never move `@`; when surgery needs to edit
  historical commits directly, spin up your own side workspace for it.
- **Exclusive**: the main checkout is yours, either because you're the only
  writer or because the human parked everyone and handed you the lock. You may
  do surgery in place — `jj edit` freely; the side-workspace machinery below is
  optional. A lock is worth requesting for bottom-up-heavy surgery: the main
  checkout has the warm build cache and env setup a fresh workspace lacks.
  Exclusive means the *checkout* is yours, not the repo: parked co-editors
  still share the op log (undo rules above still apply), and before handing
  the lock back, `jj new <tip>` so the human gets `@` parked at the tip, not
  mid-stack where your last `jj edit` left it.
- **Neither declared**: use your session context to judge how to manage the
  checkout — there is no fixed rule. Be cautious by default: the op-log
  rules above always apply when other workspaces exist, and prefer
  non-disruptive mechanisms (routing, side workspaces) when in doubt about
  who else is in the repo.

## The bare "route" command

When the user says **"route"** with little or no other context, distribute
everything currently in `@` to its home commit in the stack. Reason through
each hunk yourself and `squash --into` its home commit by change ID — don't
lean on `jj-hunk-tool absorb`'s automated blame to place them.

In co-edit mode this overrides "only ever move YOUR hunks": route moves all
of `@`, including the user's hand-written edits. Anything you cannot
confidently place, or that belongs in `@` itself, leave and tell the user.

## Co-edit mode

Work in the same jj stack and **shared working copy** as the user. The user is
reading and editing commits while parked at a specific change (`@`). Do not
move them off it.

Edit files directly even though each raw edit lands in `@`, often the
**wrong commit**. Route it afterward to its home commit with
`jj-hunk-tool`, which moves hunks between commits without checking anything
out. Leave `@` clean of your changes before handing back so the user can keep
reviewing and editing undisturbed.

Because you can always route afterward, order and who-touches-what don't
matter — no need to ask how to split or sequence the work; just make the edit
and route it home.

Combine this mode with `queue-mode` when the user queues fixes. Make and route
those fixes while the user edits the same tree; do not rely on receiving
replies.

### #1 RULE: NEVER MOVE THE CHECKOUT

`@` is where the user is reading and making fixups. Moving it changes files
underneath them during review. **Do not run any command that repoints,
replaces, or abandons `@`:**

- `jj edit <rev>` — forbidden unless the user explicitly hands you an
  exclusive working-copy lock to resolve conflicts (see
  [Co-edit conflicts](#co-edit-conflicts)).
- `jj new`, `jj checkout`, `jj co`
- `jj abandon @`, `jj squash` with no `--from` (defaults to squashing `@`
  away)
- `jj undo`, `jj op restore`, `jj op undo` — see
  [Op log](#op-log-shared-and-how-to-undo); these can revert the user's live
  work, not just yours.

Read-only jj commands are always fine (`jj log`, `jj diff`, `jj show`,
`jj file show -r <rev>`, `jj-hunk-tool hunks -r <rev>`) — read any commit
without checking it out. You never need `jj edit` to look.

### The loop

For each requested change:

1. **Edit the working-copy files** directly. The tree shows `@`'s cumulative
   state — all ancestors up to `@`.
2. **List your hunks:** `jj-hunk-tool hunks`. Identify the exact hunk IDs of
   the edit you just made — nothing else (see below).
3. **Pick the home commit** by change ID (`jj log`, blame, or
   `jj-hunk-tool absorb --dry-run` to see routing). Change IDs are stable
   across rewrites — target by change ID, never commit hash, since the user
   may rewrite commits concurrently.
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
descendant-rebases. Moving a hunk into an ancestor leaves `@`'s tree
unchanged, so run CI whenever; it sees the same files either way.

### Only ever move YOUR hunks

The user is editing the same working copy, so `@` may hold their uncommitted
work alongside yours. **Never sweep their hunks into another commit.**

- Never run a bare `jj-hunk-tool absorb` or `jj-hunk-tool squash --from @`
  with no hunk IDs — that moves *everything*, including the user's work.
- Always select the specific hunk IDs you just wrote. You know what you
  changed; if `jj-hunk-tool hunks` shows changes you do not recognize, they
  belong to the user. Leave them in `@`, untouched.
- If you genuinely cannot distinguish your hunk from the user's, **stop and
  ask.** Do not guess and risk moving the user's work.

### When the change belongs in `@`

If a change genuinely belongs in `@` itself (where the user is parked), leave
it there and tell the user. Since you may both be in that file, expect the
occasional collision.

### We're editing the same files at once

Expect the occasional failed or clobbered edit — the user or another AI may be
editing the same file at the same moment. Do not let it stop you.

- If your edit didn't apply, or got overwritten alongside other changes to the
  file, just redo it.
- If code you wrote was changed but not reverted, keep the user's or AI
  co-editor's version — usually a cleanup or style fix to respect.
- If your work was cleanly reverted with no other change to the file, the user
  or an AI co-editor likely rejected that change; raise it if you think
  that's a mistake.

### Co-edit conflicts

Routing a hunk into an ancestor rebases its descendants (including `@`), and
jj records any conflict in the tree instead of stopping. So after a move,
check `jj log` for conflict markers, and resolve by editing the files — not
by undoing. If a conflict is ambiguous or you are stuck, leave it and tell
the user.

Some conflicts can't be resolved from `@` at all: when several stacked
commits touch one file, a higher commit's version **masks** the lower ones',
so `@` never shows what each ancestor actually needs, and routing a partial
fix down just nests the conflict or bakes literal marker text into a commit.
Resolving these conflicts needs a bottom-up `jj edit` pass, which moves `@`.
You can do this without disturbing anyone: create your own
[side workspace](#side-workspace-edit-any-commit-without-moving-anyones-)
and do the bottom-up pass there — the shared `@` never moves. Afterward
re-sync the shared workspace's git view (see the re-export bullet under
[Verification](#verification)). If that is impractical, stop and ask for an
exclusive working-copy lock. Once the user confirms that their work and any
other agents are parked, you may `jj edit` each commit directly to fix the
conflicts. Work bottom-up and fully resolve each commit before moving to the
next one up — no markers left, `jj resolve --list` clean, and it builds;
leaving a conflict behind just cascades new ones into its descendants.
`jj new` back to the tip when done.

### Carry things forward

Do not bury questions, judgment calls, or important notes in a reply the user
may never see. Retain them and surface the accumulated notes once it is clear
that the user has returned to the chat.

## Side workspace: edit any commit without moving anyone's `@`

The core tool for surgery in a shared repo. A workspace is a second checkout
with its own `@` but shared graph and op log, so `jj edit` there never
disturbs the main checkout. Workspaces are per-agent sandboxes: create your
own under a task-distinct name, and never `jj edit` or snapshot inside a
workspace you didn't create — another agent is parked there.

```sh
jj workspace add ~/worktrees/ai/<task> --revision <rev>
cd ~/worktrees/ai/<task> && jj edit <target-change-id>
# edit files, run builds/codegen...
jj status        # snapshot! descendants rebase now, not before
```

Some lessons previous AIs have learned the hard way:

- The fresh checkout lacks untracked infra: copy `.env` or look for a
  `worktree-setup` just command, run the package manager (pub get /
  npm install), and warm the cold build cache (a first `cargo check`).
  Run long builds in the background while you keep working.
- When editing several commits, go bottom-up and finish each one (no markers,
  compiles) before moving up; a half-resolved commit cascades nested conflicts
  into everything above it.
- Before cleanup, audit each commit you edited for contamination — lockfiles,
  `.env`, formatter churn: `jj diff --stat -r <rev>`.
- Cleanup: park the workspace `@` off the stack (`jj new <tip>`), then
  `jj workspace forget <name>` and `rm -rf` the directory.

## Choosing the mechanism

Three main ways to change a commit's content; pick per change, they compose:

1. **Route from tip** (`jj-hunk-tool squash/absorb`): when the lines you're
   changing still exist at tip. Edit in the working copy, move the hunks to
   their home commit; every tree above the home updates automatically.
   Cheapest — no workspace, no conflicts if the lines flowed through
   untouched.
2. **Edit the commit directly** (via side workspace in shared mode): when the
   change involves lines a later commit deleted or rewrote — tip has nothing
   to route, and routing what it *does* have leaves intermediate trees broken
   (e.g. renamed definition + un-renamed use = a commit that doesn't
   compile). Also the only way to author content that exists in *no* diff,
   e.g. re-running codegen to produce an intermediate generated state.
3. **Pin to a known tree**: `jj restore --from <good-commit> --into <rev>
   <paths>` forces a commit's files to a known-good state in one move —
   dissolves a whole conflict cascade when a commit's final tree should be
   byte-identical to a pre-surgery snapshot.

Structural edits:

- Insert a prefactor: `jj new --no-edit -B <rev> -m "..."` — `--no-edit`
  keeps `@` parked. Fill it via mechanism 1 or 2.
- Fold an existing commit into another: `jj squash --from <x> --into <p>
  --use-destination-message` — the source is auto-abandoned when emptied.
- Split a commit whose pieces all exist in its diff: `jj split <paths> -m`
  by file, `jj-hunk-tool split <id...> -r <rev> -m` by hunk (`-A`/`-B`/`-p`
  control placement).
- A split whose middle state never existed in any diff = insert an empty
  commit, then edit it directly.

## Conflicts

- Conflicts live in trees and propagate to all descendants — anyone parked at
  tip sees markers *immediately*, so resolve sources fast. `jj log -r
  'conflicts()'` lists carriers; `jj resolve --list -r <rev>` separates true
  sources from inherited ones (inherited clear on their own once the source
  resolves — don't chase them).
- jj markers differ from git: `<<<<<<<` … `%%%%%%%` (a *diff* to re-apply) …
  `+++++++` (a snapshot side) … `>>>>>>>`. When your rewrite raced a
  restructure, the usual resolution is: keep the snapshot side, then re-apply
  your transformation to it (same sed you used originally).
- **Generated files: never text-merge.** Resolve by re-running the generator
  at that commit, and re-generate at every descendant that itself
  regenerates, bottom-up. Text-merged codegen output can pass today and
  break the next regen.
- **Scripted resolutions and renames rarely land on the formatter's fixed
  point** — splicing a side or changing identifier lengths reflows nothing,
  so import lists and wrapped lines drift and tip CI fails format-check even
  though everything compiles. Run the formatter at each commit you edited
  (snapshot after), and include a tip format-check in verification.

## Concurrency with co-editors

Ops from any workspace race yours — the human's main checkout and every peer
agent's workspace. Expect and handle:

- **Stale working copies**: any other workspace's op leaves yours stale; run
  `jj workspace update-stale` and continue. "Updated working copy to fresh
  commit" means the `@` identity churned; its position and tree did not.
- **Forked lineages**: simultaneous ops can duplicate part of the stack —
  divergent change IDs, addressed as `change_id(xyz)` or `xyz/0`, `xyz/1`.
  Diagnose with a graph log templated to show `working_copies` and `empty`:
  the live lineage is the one holding the working copies. Confirm the
  duplicate tips' trees match (`jj diff --from A --to B` → 0 files changed),
  then `jj abandon <dead-lineage-root-commit-id>::`. If working copies ended
  up split *across* lineages, don't pick a winner unilaterally — stop and
  coordinate. Divergence may also predate you: compare against
  `jj --at-op=<your-first-op>- log -r 'all()'` templated on `divergent` to
  prove which duplicates you actually created before cleaning any up.
- **Bookmark conflicts** come from the same races; resolve with
  `jj bookmark set <name> -r <survivor>` (usually right where it was, on the
  surviving lineage).
- If a co-editor's edits changed code you wrote, keep their version. If your
  work was cleanly reverted, they rejected the approach — ask if you think it
  was a mistake, don't redo.

## Verification

"As if it had always been this way" is testable, not vibes:

- **Per-commit tree grep** (colocated repos): `git grep -E '<old-pattern>'
  <commit-id> -- '*.rs'` for *every* stack commit — catches broken
  intermediate trees that a tip-only check can't see.
- **Tree identity**: `jj diff --from <pre-surgery-tip-commit-id> --to <tip>`
  must be empty or exactly the intended delta. Record the old tip's commit ID
  before you start; hidden commits remain valid diff operands.
- **Compile matrix**: full check at every commit you edited; full CI at tip.
  Commits you didn't touch that also grep clean are low-risk.
- Final sweep before handing back: `jj log -r 'conflicts()'` empty, no
  divergent-change warnings, and every workspace's `@` where its owner left
  it.
- **Re-export peers' git HEAD** (colocated): after surgery from a side
  workspace, peer workspaces' git HEADs still name the pre-rewrite stack —
  git tools there (vgit, `git status`) silently read old commits. Bookmarks
  export fine; HEAD lags, and for linked-worktree workspaces jj may not
  manage HEAD at all (`jj st` / `jj git export` won't fix it). In each
  affected workspace, verify `git rev-parse HEAD` matches `@-`'s commit; if
  not, `git reset <commit-of-@->` (mixed: moves HEAD + index, leaves files).

## jj-hunk-tool quick reference

```sh
jj-hunk-tool hunks [-r rev] [--file f]      # list hunks: 7-hex IDs + line numbers
jj-hunk-tool patch <id[:5-30]> [-r rev]     # unified diff of selected hunks
jj-hunk-tool split <id...> -r <rev> -m ""   # split hunks out (-A/-B/-p placement)
jj-hunk-tool squash <id...> --into <rev>    # move hunks between commits
jj-hunk-tool absorb [<id>...] [--dry-run]   # blame-routed; ALWAYS pass IDs in a shared @
jj-hunk-tool restore <id...> [-c rev]       # undo hunks (from @, or introduced by rev)
jj-hunk-tool diffedit <id...> -r <rev>      # keep only selected hunks in rev
```

IDs are content-derived and go stale after any change — re-run `hunks`. Line
ranges: `id:2-6,30-41`. Absorb routes modified/deleted lines by blame; pure
insertions fall back to the last mutable ancestor touching the file;
ambiguous hunks stay in `@` with candidates printed.
