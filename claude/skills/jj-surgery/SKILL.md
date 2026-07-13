---
name: jj-surgery
description: History surgery on a jj repo — splitting commits, inserting prefactors, propagating renames through a stack, rewriting intermediate commits — often in a live repo shared with a human or other agents. Covers side-workspace editing, conflict cascades, generated files, concurrent-op forks, and verification.
---

# jj Surgery

Rewriting a stack in place: splits, prefactors, renames that must read as if
they "had always been that way". Everything here leans on two jj facts: every
rewrite auto-rebases all descendants, and conflicts are recorded data, not
stop-signs.

## Operating modes

Who owns the main checkout determines how you work (see jj-coedit):

- **Shared** (the jj-coedit default): the human owns `@`, and everyone —
  human and agents alike — edits the same working copy, staying out of each
  other's way per jj-coedit. Never move `@`; when surgery needs to edit
  historical commits directly, spin up your own side workspace for it (that's
  what workspaces are for here — ad hoc escalation, not permanent silos).
  Expect concurrent operations from every direction.
- **Exclusive**: the main checkout is yours, either because you're the only
  writer or because the human parked everyone and handed you the lock. Do
  surgery in place — `jj edit` freely; the side-workspace machinery below is
  optional. A lock is worth requesting for bottom-up-heavy surgery: the main
  checkout has the warm build cache and env setup a fresh workspace lacks.
  When co-editors exist, the op log is still shared — undo rules and
  peer-workspace cautions below still apply — and `jj new <tip>` before
  handing the lock back.

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

One op log spans all workspaces of a repo. Consequences:

- **NEVER `jj op restore` to undo your own work** — it rewinds *every*
  workspace, clobbering the human's and every peer agent's concurrent work.
  Use `jj undo` (last op only) or `jj op revert <op-id>` (inverts one
  targeted op).
- `jj op log` is the forensics tool. When state looks wrong, read the last
  ~10 ops *before* concluding breakage — often the human or a peer agent
  squashed or renamed under you, in which case keep their change and adapt
  yours.
- Recover files from the past without touching the op timeline:
  `jj --at-op=<op> file show`, or `jj restore --from <old-commit-id>` —
  hidden commits stay addressable by commit ID for diff and restore.

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
   Cheapest — no workspace, no conflicts if the lines flowed through untouched.
2. **Edit the commit directly** (via side workspace in shared mode): when the
   change involves lines a later commit deleted or rewrote — tip has nothing
   to route, and routing what it *does* have leaves intermediate trees broken
   (e.g. renamed
   definition + un-renamed use = a commit that doesn't compile). Also the only
   way to author content that exists in *no* diff, e.g. re-running codegen to
   produce an intermediate generated state.
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
  at that commit, and re-generate at every descendant that itself regenerates,
  bottom-up. Text-merged codegen output can pass today and break the next
  regen.
- **Scripted resolutions and renames rarely land on the formatter's fixed
  point** — splicing a side or changing identifier lengths reflows nothing, so
  import lists and wrapped lines drift and tip CI fails format-check even
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
  coordinate.
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
  divergent-change warnings, and every workspace's `@` where its owner left it.

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
