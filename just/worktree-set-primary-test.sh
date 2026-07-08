#!/usr/bin/env bash
# NOTE: no `set -e` — the suites intentionally run failing commands
# (conflicting merges, rebases stopped mid-conflict, ...) and count assertion
# failures instead of aborting on them.
set -uo pipefail

usage() {
  cat << EOF
USAGE: just worktree-set-primary-test [git|jj|stress]...

Integration tests for the \`worktree-set-primary\` recipe in
just/global.justfile (the SOURCE recipe, not the deployed ~/.config copy —
so you can iterate on the recipe and test before running hms).

Builds throwaway colocated git+jj repos in a temp dir, then swaps the primary
worktree while git and jj operations are in every state that holds mutable
on-disk state: dirty/staged files, merges and rebases stopped on conflicts,
bisects, cherry-pick sequences, stashes, jj WIP changes, bookmarks, conflicted
jj commits, moved changes, the op log. Asserts that no swap ever changes any
worktree's files, status, HEAD, or refs, and that every in-progress operation
completes correctly afterward.

Suites (default: all):
  git      dirty states, merge/rebase conflicts, autosquash, bisect,
           cherry-pick, stash
  jj       WIP @, bookmarks, jj conflicts, squash/rebase/duplicate, undo,
           git<->jj interleave
  stress   9 primary rotations with concurrent git+jj work and a worktree
           held mid-rebase throughout

The temp dir is deleted on success and preserved on failure for inspection.
EOF
}

for dep in git jj just perl; do
  if ! command -v "$dep" &> /dev/null; then
    echo >&2 "error: '$dep' unavailable"
    exit 1
  fi
done

# Test the source recipe next to this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GJF="$script_dir/global.justfile"

# Hermetic environment: no user git/jj config, no interactive editors.
export EDITOR=true GIT_EDITOR=true JJ_EDITOR=true
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=t@t
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=t@t
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export JJ_CONFIG=/dev/null JJ_USER=test JJ_EMAIL=t@t

# Template form works with both GNU and BSD mktemp. Guard hard against an
# empty $WORK: every path below hangs off it, including rm -rf.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/worktree-set-primary-test.XXXXXX")"
if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
  echo >&2 "error: mktemp failed"
  exit 1
fi
W="$WORK/work"

PASS=0
FAIL=0

on_exit() {
  if [ "$FAIL" -eq 0 ]; then
    rm -rf "$WORK"
  else
    echo >&2 "Fixtures preserved for inspection: $WORK"
  fi
}
trap on_exit EXIT

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

ok()  { echo "  ok  $1"; PASS=$((PASS+1)); }
bad() { echo "  BAD $1"; FAIL=$((FAIL+1)); }

# Conditions eval without pipefail: `grep -q` exiting early SIGPIPEs upstream
# commands (jj maps a broken pipe to exit 3), turning passing pipelines into
# false failures.
chk() {
  if ( set +o pipefail; eval "$2" ) > /dev/null 2>&1; then
    ok "$1"
  else
    bad "$1  [cond: $2]"
  fi
}

# enter DIR: cd or die. Every fixture cd MUST use this: without `set -e`, a
# failed bare `cd` leaves the shell in the *invoking* directory — likely a real
# repo — where the fixture's relative git/jj commands would then run.
enter() {
  cd "$1" || { echo >&2 "fatal: cd $1 failed; aborting to protect cwd"; exit 70; }
}

# replace OLD NEW FILE: portable in-place literal replacement (no sed -i,
# whose flags differ between GNU and BSD).
replace() {
  local content
  content="$(cat "$3")"
  printf '%s\n' "${content//"$1"/$2}" > "$3"
}

if command -v md5 > /dev/null 2>&1; then
  hash_files() { xargs -0 md5 -r 2> /dev/null; }
else
  hash_files() { xargs -0 md5sum 2> /dev/null; }
fi

# SP <dir>: set <dir> as primary via the recipe under test, invoked with NO
# ARG from inside the dir (exercises the cwd-default path every time).
# Asserts success and that <dir> really is primary afterwards.
SP() {
  local dir="$1"
  if ! ( cd "$dir" && just -f "$GJF" -d . worktree-set-primary ) > "$WORK/sp.log" 2>&1; then
    bad "set-primary $dir failed"
    sed 's/^/    | /' "$WORK/sp.log"
    return 1
  fi
  local c g
  c="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)"
  g="$(git -C "$dir" rev-parse --path-format=absolute --git-dir)"
  if [ "$c" = "$g" ]; then
    ok "set-primary -> $(basename "$dir")"
  else
    bad "set-primary $dir: not primary after run"
    return 1
  fi
}

# snap <dir>: fingerprint a worktree: git status, HEAD, branch, file hashes.
# The swap itself must never change any of this, in any worktree.
snap() {
  local d="$1"
  git -C "$d" status --porcelain
  git -C "$d" rev-parse HEAD 2> /dev/null
  git -C "$d" symbolic-ref -q HEAD || echo detached
  ( cd "$d" && find . \( -name .git -o -name .jj \) -prune -o -type f -print0 \
      | sort -z | hash_files )
}

# SWAP_CHECK <target> <wt...>: snapshot all worktrees, swap primary to target,
# assert every snapshot is unchanged, then run integrity checks.
SWAP_CHECK() {
  local target="$1"; shift
  local d i=0
  local pre=()
  for d in "$@"; do pre[$i]="$(snap "$d")"; i=$((i+1)); done
  SP "$target" || return 1
  i=0
  for d in "$@"; do
    if [ "$(snap "$d")" = "${pre[$i]}" ]; then
      ok "swap preserved $(basename "$d") state"
    else
      bad "swap CHANGED $(basename "$d") state"
      diff <(echo "${pre[$i]}") <(snap "$d") | head -20 | sed 's/^/    | /'
    fi
    i=$((i+1))
  done
  integrity "$target"
}

# integrity <primary>: repo-wide invariants that must hold after any swap.
integrity() {
  local m="$1"
  chk "fsck clean" "[ -z \"\$(git -C '$m' fsck --no-progress --strict 2>&1 | grep -v '^Checking\|^dangling\|^notice')\" ]"
  chk "worktree list ok" "git -C '$m' worktree list"
  local wt
  while IFS= read -r wt; do
    chk "git status ok in $(basename "$wt")" "git -C '$wt' status"
  done < <(git -C "$m" worktree list --porcelain | awk '/^worktree /{print $2}')
  if [ -d "$m/.jj" ]; then
    chk "jj status ok"  "( cd '$m' && jj --ignore-working-copy status )"
    chk "jj op log ok"  "( cd '$m' && jj --ignore-working-copy op log --limit 1 )"
    chk "jj log all ok" "( cd '$m' && jj --ignore-working-copy log -r 'all()' )"
  fi
}

# build: fresh fixture. Primary A (branch main, colocated jj), linked
# worktrees B (feat-b) and C (feat-c). A few base commits.
build() {
  rm -rf "$W"
  mkdir -p "$W" || exit 70
  git -C "$W" init -q A -b main
  enter "$W/A"
  printf 'alpha\nbeta\ngamma\ndelta\n' > shared.txt
  for i in 1 2 3; do echo "content $i" > "f$i.txt"; done
  git add -A; git commit -qm "base: initial files"
  echo more >> f1.txt; git commit -qam "base: grow f1"
  jj git init --colocate > /dev/null 2>&1
  git worktree add -q -b feat-b "$W/B"
  git worktree add -q -b feat-c "$W/C"
}

cid()    { jj log -r @ --no-graph -T change_id; }         # change id of @
lastop() { jj op log --limit 1 --no-graph | awk '{print $1; exit}'; }

# ---------------------------------------------------------------------------
# Suite: git — every git operation that holds mutable per-worktree state
# ---------------------------------------------------------------------------

suite_git() {
  echo "=== T1: dirty working states survive swaps; no-arg/subdir/no-op forms ==="
  build
  # A: every flavor of dirtiness
  enter "$W/A"
  echo untracked > new.txt                 # untracked
  echo edit >> f1.txt                      # modified, unstaged
  echo edit >> f2.txt; git add f2.txt      # modified, staged
  git rm -q f3.txt                         # deleted, staged
  rm shared.txt                            # deleted, unstaged
  # B: its own mix
  enter "$W/B"
  echo bnew > bnew.txt; git add bnew.txt   # new file, staged
  echo bedit >> f1.txt                     # modified, unstaged
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  chk "T1: .jj not in git status of new primary" "! git -C '$W/B' status --porcelain | grep -q .jj"
  # commit staged work in demoted A; verify it lands
  git -C "$W/A" commit -qm "A: staged work" 2> /dev/null
  chk "T1: commit in demoted A works" "git -C '$W/A' log -1 --format=%s | grep -q 'A: staged work'"
  chk "T1: A staged-delete of f3 committed" "! git -C '$W/A' cat-file -e HEAD:f3.txt"
  chk "T1: A unstaged edit still pending" "git -C '$W/A' status --porcelain | grep -q ' M f1.txt'"
  # subdir invocation
  mkdir -p "$W/C/sub/deep"
  ( cd "$W/C/sub/deep" && just -f "$GJF" -d . worktree-set-primary ) > /dev/null 2>&1
  chk "T1: no-arg from subdir resolves worktree root" \
      "[ \"\$(git -C '$W/C' rev-parse --path-format=absolute --git-common-dir)\" = \"\$(git -C '$W/C' rev-parse --path-format=absolute --git-dir)\" ]"
  # no-op when already primary
  local out
  out="$(cd "$W/C" && just -f "$GJF" -d . worktree-set-primary 2>&1)"
  chk "T1: already-primary is a no-op" "echo \"\$out\" | grep -q 'already the primary'"
  integrity "$W/C"

  echo "=== T2: merge conflicts (in swap target, and in a bystander) ==="
  build
  replace gamma gamma-b "$W/B/shared.txt";    git -C "$W/B" commit -qam "B: gamma"
  replace gamma gamma-main "$W/A/shared.txt"; git -C "$W/A" commit -qam "main: gamma"
  git -C "$W/B" merge main > /dev/null 2>&1
  chk "T2: B is mid-merge with conflict" "git -C '$W/B' status --porcelain | grep -q '^UU shared.txt'"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"     # swap INTO the mid-merge worktree
  chk "T2: MERGE_HEAD survived promotion" "[ -f '$W/B/.git/MERGE_HEAD' ]"
  replace gamma-b gamma-merged "$W/B/shared.txt"
  git -C "$W/B" add shared.txt; git -C "$W/B" commit -q --no-edit
  chk "T2: merge commit created (2 parents)" "[ \"\$(git -C '$W/B' rev-list --parents -1 HEAD | wc -w)\" -eq 3 ]"
  # bystander: C mid-merge while primary swaps B -> A
  replace delta delta-c "$W/C/shared.txt";    git -C "$W/C" commit -qam "C: delta"
  replace delta delta-main "$W/A/shared.txt"; git -C "$W/A" commit -qam "main: delta"
  git -C "$W/C" merge main > /dev/null 2>&1
  chk "T2: C is mid-merge with conflict" "git -C '$W/C' status --porcelain | grep -q '^UU shared.txt'"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"     # C is a bystander
  replace delta-c delta-merged "$W/C/shared.txt"
  git -C "$W/C" add shared.txt; git -C "$W/C" commit -q --no-edit
  chk "T2: bystander C completed its merge" "[ \"\$(git -C '$W/C' rev-list --parents -1 HEAD | wc -w)\" -eq 3 ]"
  integrity "$W/A"

  echo "=== T3: mid-rebase across swaps (promote into it; demote out of it) ==="
  build
  replace alpha alpha-main "$W/A/shared.txt"; git -C "$W/A" commit -qam "main: alpha"
  replace alpha alpha-c1 "$W/C/shared.txt";   git -C "$W/C" commit -qam "c1: alpha"
  echo epsilon >> "$W/C/shared.txt";          git -C "$W/C" commit -qam "c2: epsilon"
  git -C "$W/C" rebase main > /dev/null 2>&1
  chk "T3: C stopped on rebase conflict" "git -C '$W/C' status | grep -q 'rebase in progress'"
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"     # promote the mid-rebase worktree
  chk "T3: rebase state at new primary top" "[ -d '$W/C/.git/rebase-merge' ]"
  printf 'alpha-resolved\nbeta\ngamma\ndelta\n' > "$W/C/shared.txt"
  ( cd "$W/C" && git add shared.txt && git rebase --continue ) > /dev/null 2>&1
  chk "T3: rebase completed after promote" "git -C '$W/C' log -1 --format=%s | grep -q 'c2: epsilon'"
  chk "T3: rebased history is linear on main" "git -C '$W/C' merge-base --is-ancestor main feat-c"
  # now the reverse: start a rebase in primary C, demote it mid-conflict.
  # add/add conflict on a fresh file so only c3 conflicts during the replay.
  echo main-version > "$W/A/conflict2.txt"
  git -C "$W/A" add conflict2.txt; git -C "$W/A" commit -qm "main: conflict2"
  echo c3-version > "$W/C/conflict2.txt"
  git -C "$W/C" add conflict2.txt; git -C "$W/C" commit -qm "c3: conflict2"
  git -C "$W/C" rebase main > /dev/null 2>&1
  chk "T3: primary C mid-rebase" "git -C '$W/C' status | grep -q 'rebase in progress'"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"     # demote the mid-rebase primary
  echo resolved2 > "$W/C/conflict2.txt"
  ( cd "$W/C" && git add conflict2.txt && git rebase --continue ) > /dev/null 2>&1
  chk "T3: rebase completed after demote" "git -C '$W/C' log -1 --format=%s | grep -q 'c3: conflict2'"
  integrity "$W/A"

  echo "=== T4: fixup + autosquash, squash, amend, reflog continuity ==="
  build
  enter "$W/B"
  echo one > x.txt; git add x.txt; git commit -qm "add x"
  local xsha
  xsha="$(git rev-parse HEAD)"
  echo y > y.txt; git add y.txt; git commit -qm "add y"
  echo two >> x.txt; git commit -qa --fixup="$xsha"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  ( cd "$W/B" && GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash main ) > /dev/null 2>&1
  chk "T4: autosquash squashed the fixup" "[ \"\$(git -C '$W/B' rev-list --count main..feat-b)\" -eq 2 ]"
  chk "T4: fixup content folded into x"   "[ \"\$(git -C '$W/B' show HEAD~1:x.txt | tr '\n' ' ')\" = 'one two ' ]"
  chk "T4: original message kept"          "git -C '$W/B' log --format=%s | grep -qx 'add x'"
  chk "T4: reflog recorded the rebase"     "git -C '$W/B' reflog | grep -q 'rebase (finish)'"
  # squash two commits in C after another swap
  enter "$W/C"
  echo s1 > s.txt; git add s.txt; git commit -qm "s1"
  echo s2 >> s.txt; git commit -qam "s2"
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"
  ( cd "$W/C" \
    && GIT_SEQUENCE_EDITOR='perl -pi -e "s/^pick/squash/ if $. == 2"' git rebase -i main ) > /dev/null 2>&1
  chk "T4: squash collapsed to 1 commit" "[ \"\$(git -C '$W/C' rev-list --count main..feat-c)\" -eq 1 ]"
  chk "T4: squashed content intact" "[ \"\$(git -C '$W/C' show HEAD:s.txt | tr '\n' ' ')\" = 's1 s2 ' ]"
  # amend in the demoted old primary
  echo amended >> "$W/B/y.txt"
  git -C "$W/B" commit -qam "will be amended"
  git -C "$W/B" commit -q --amend -m "amended message"
  chk "T4: amend works in demoted worktree" "git -C '$W/B' log -1 --format=%s | grep -qx 'amended message'"
  integrity "$W/C"

  echo "=== T5: bisect spanning multiple swaps ==="
  build
  enter "$W/C"
  local good bugsha i res
  good="$(git rev-parse HEAD)"
  bugsha=""
  for i in 1 2 3 4 5 6 7 8; do
    echo "step $i" >> log.txt
    [ "$i" -eq 5 ] && echo broken > bug.txt
    git add -A; git commit -qm "step $i"
    [ "$i" -eq 5 ] && bugsha="$(git rev-parse HEAD)"
  done
  git -C "$W/C" bisect start HEAD "$good" > /dev/null 2>&1
  bstep() {
    if [ -f "$W/C/bug.txt" ]; then git -C "$W/C" bisect bad; else git -C "$W/C" bisect good; fi
  }
  bstep > /dev/null 2>&1
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"     # promote mid-bisect
  bstep > /dev/null 2>&1
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"     # demote mid-bisect
  res=""
  for _ in 1 2 3 4 5; do
    res="$(bstep 2> /dev/null)"
    echo "$res" | grep -q "is the first bad commit" && break
  done
  chk "T5: bisect found the culprit across swaps" "echo \"\$res\" | grep -q \"^$bugsha\""
  git -C "$W/C" bisect reset > /dev/null 2>&1
  chk "T5: bisect reset restored branch" "[ \"\$(git -C '$W/C' symbolic-ref --short HEAD)\" = feat-c ]"
  integrity "$W/A"

  echo "=== T6: cherry-pick sequence with mid-sequence conflict + stash ==="
  build
  enter "$W/B"
  local b1 b3
  echo cp1 > cp1.txt; git add cp1.txt; git commit -qm "b1: cp1"
  b1="$(git rev-parse HEAD)"
  replace beta beta-b2 shared.txt; git commit -qam "b2: beta"
  echo cp3 > cp3.txt; git add cp3.txt; git commit -qm "b3: cp3"
  b3="$(git rev-parse HEAD)"
  replace beta beta-main "$W/A/shared.txt"; git -C "$W/A" commit -qam "main: beta"
  git -C "$W/A" cherry-pick "$b1^..$b3" > /dev/null 2>&1
  chk "T6: A stopped mid-sequence on b2" "[ -f '$W/A/.git/CHERRY_PICK_HEAD' ] && [ -d '$W/A/.git/sequencer' ]"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"     # demote mid-cherry-pick primary
  replace beta-main beta-resolved "$W/A/shared.txt"
  ( cd "$W/A" && git add shared.txt && git cherry-pick --continue ) > /dev/null 2>&1
  chk "T6: full sequence applied after swap" "[ \"\$(git -C '$W/A' rev-list --count main ^main~3)\" -eq 3 ] && [ -f '$W/A/cp1.txt' ] && [ -f '$W/A/cp3.txt' ]"
  # stash across a swap
  echo stashme >> "$W/B/f2.txt"
  git -C "$W/B" stash push -qm "tmp work"
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"
  git -C "$W/B" stash pop -q
  chk "T6: stash pop after swap restores edit" "grep -q stashme '$W/B/f2.txt'"
  chk "T6: stash empty after pop" "[ -z \"\$(git -C '$W/B' stash list)\" ]"
  integrity "$W/C"
}

# ---------------------------------------------------------------------------
# Suite: jj — jj state across swaps; jj only runs in the current primary
# ---------------------------------------------------------------------------

suite_jj() {
  echo "=== J1: jj WIP (@ is the working copy commit) across swaps ==="
  build
  enter "$W/A"
  local wip_cid wip_op
  echo "precious wip" > wip.txt
  jj status > /dev/null 2>&1                  # snapshot into @
  jj describe -m "wip-A" > /dev/null 2>&1
  wip_cid="$(cid)"; wip_op="$(lastop)"
  chk "J1: @ described as wip-A" "jj log -r @ --no-graph -T description | grep -q wip-A"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  ( cd "$W/B" && jj status ) > /dev/null 2>&1   # first real jj cmd in new primary
  chk "J1: jj adopted new primary B" "( cd '$W/B' && jj log -r @ )"
  chk "J1: wip file still on disk in old primary A" "grep -q 'precious wip' '$W/A/wip.txt'"
  chk "J1: A still sees wip.txt as untracked in git" "git -C '$W/A' status --porcelain | grep -q 'wip.txt'"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  ( cd "$W/A" && jj status ) > /dev/null 2>&1   # re-snapshot A: wip content returns to @
  chk "J1: re-snapshot recovered wip content into @" "( cd '$W/A' && jj file show -r @ wip.txt ) | grep -q 'precious wip'"
  ( cd "$W/A" && jj op restore "$wip_op" ) > /dev/null 2>&1
  chk "J1: op restore recovers the named WIP change" "( cd '$W/A' && jj log -r @ --no-graph -T 'change_id ++ description' ) | grep -q wip-A"
  chk "J1: restored @ is the original change id" "( cd '$W/A' && cid ) | grep -q \"$wip_cid\""
  integrity "$W/A"

  echo "=== J2: bookmarks across swaps ==="
  ( cd "$W/A" && jj bookmark create bm-1 -r @- ) > /dev/null 2>&1
  chk "J2: bm-1 created" "( cd '$W/A' && jj bookmark list ) | grep -q bm-1"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  chk "J2: bm-1 visible from new primary" "( cd '$W/B' && jj --ignore-working-copy bookmark list ) | grep -q bm-1"
  ( cd "$W/B" && jj status && jj bookmark create bm-2 -r @- ) > /dev/null 2>&1
  ( cd "$W/B" && jj bookmark set bm-1 -r @- --allow-backwards ) > /dev/null 2>&1
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"
  chk "J2: both bookmarks survive second swap" "[ \"\$(cd '$W/C' && jj --ignore-working-copy bookmark list | grep -c 'bm-[12]')\" -ge 2 ]"
  chk "J2: bm-1 resolvable in jj log" "( cd '$W/C' && jj --ignore-working-copy log -r bm-1 )"
  chk "J2: bm-1 exported as git branch" "git -C '$W/C' show-ref --verify refs/heads/bm-1"
  chk "J2: bm-1 points at feat-b tip" "[ \"\$(git -C '$W/C' rev-parse bm-1)\" = \"\$(git -C '$W/C' rev-parse feat-b)\" ]"
  integrity "$W/C"

  echo "=== J3: jj merge conflict survives swaps; resolvable after ==="
  build
  enter "$W/A"
  local s1 s2
  jj new main -m side1 > /dev/null 2>&1; echo one > c.txt; jj status > /dev/null 2>&1
  s1="$(cid)"
  jj new main -m side2 > /dev/null 2>&1; echo two > c.txt; jj status > /dev/null 2>&1
  s2="$(cid)"
  jj rebase -s "$s2" -d "$s1" > /dev/null 2>&1
  chk "J3: rebase created conflicted commit" "( cd '$W/A' && jj log -r '$s2' --no-graph ) | grep -qi conflict"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  chk "J3: conflict visible from new primary (no snapshot)" "( cd '$W/B' && jj --ignore-working-copy log -r '$s2' --no-graph ) | grep -qi conflict"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  ( cd "$W/A" && jj edit "$s2" ) > /dev/null 2>&1
  chk "J3: conflict markers materialized on edit" "grep -q '<<<<<<<' '$W/A/c.txt'"
  echo resolved > "$W/A/c.txt"
  ( cd "$W/A" && jj status ) > /dev/null 2>&1
  chk "J3: conflict resolved after round-trip swaps" "! ( cd '$W/A' && jj log -r '$s2' --no-graph | grep -qi conflict )"
  chk "J3: resolved content correct" "( cd '$W/A' && jj file show -r '$s2' c.txt ) | grep -qx resolved"
  integrity "$W/A"

  echo "=== J4: moving changes (squash --from/--into, rebase, duplicate) across swaps ==="
  build
  enter "$W/A"
  local x y z
  jj new main -m "feat-x" > /dev/null 2>&1; echo x1 > x.txt; jj status > /dev/null 2>&1
  x="$(cid)"
  jj new -m "feat-y" > /dev/null 2>&1; echo y1 > y.txt; jj status > /dev/null 2>&1
  y="$(cid)"
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  ( cd "$W/A" && jj squash --from "$y" --into "$x" -m "feat-xy" ) > /dev/null 2>&1
  chk "J4: squash merged content across swaps" "( cd '$W/A' && jj file list -r '$x' ) | grep -q x.txt && ( cd '$W/A' && jj file list -r '$x' ) | grep -q y.txt"
  chk "J4: squash message applied" "( cd '$W/A' && jj log -r '$x' --no-graph -T description ) | grep -q feat-xy"
  ( cd "$W/A" && jj new main -m "feat-z" ) > /dev/null 2>&1
  echo z1 > "$W/A/z.txt"; ( cd "$W/A" && jj status ) > /dev/null 2>&1
  z="$(cd "$W/A" && cid)"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  ( cd "$W/A" && jj rebase -s "$x" -d "$z" ) > /dev/null 2>&1
  chk "J4: rebase moved x onto z" "( cd '$W/A' && jj log --no-graph -r \"children($z)\" -T 'change_id ++ \"\\n\"' ) | grep -q \"$x\""
  ( cd "$W/A" && jj duplicate "$x" ) > /dev/null 2>&1
  chk "J4: duplicate works" "[ \"\$(cd '$W/A' && jj log --no-graph -r 'description(substring:\"feat-xy\")' -T 'change_id ++ \"\\n\"' | wc -l)\" -eq 2 ]"
  integrity "$W/A"

  echo "=== J5: op log continuity + undo after many swaps ==="
  ( cd "$W/A" && jj describe -r "$z" -m "z-tmp-described" ) > /dev/null 2>&1
  SWAP_CHECK "$W/C" "$W/A" "$W/B" "$W/C"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  chk "J5: op log intact after swaps" "( cd '$W/A' && jj --ignore-working-copy op log --limit 5 )"
  ( cd "$W/A" && jj undo ) > /dev/null 2>&1
  chk "J5: undo reverted the describe" "! ( cd '$W/A' && jj log -r '$z' --no-graph -T description | grep -q z-tmp-described )"
  integrity "$W/A"

  echo "=== J6: git <-> jj interleave; reattach detached HEAD; import git commits ==="
  chk "J6: jj detached git HEAD in primary (expected)" "! git -C '$W/A' symbolic-ref -q HEAD"
  ( cd "$W/A" && git switch -q main )
  chk "J6: git switch reattaches HEAD" "[ \"\$(git -C '$W/A' symbolic-ref --short HEAD)\" = main ]"
  echo gitside > "$W/A/gitside.txt"
  git -C "$W/A" add gitside.txt; git -C "$W/A" commit -qm "git-side commit"
  ( cd "$W/A" && jj status ) > /dev/null 2>&1
  chk "J6: jj imported git-side commit" "( cd '$W/A' && jj log -r 'main@git' --no-graph -T description ) | grep -q 'git-side commit'"
  SWAP_CHECK "$W/B" "$W/A" "$W/B" "$W/C"
  SWAP_CHECK "$W/A" "$W/A" "$W/B" "$W/C"
  chk "J6: git-side commit still in jj view" "( cd '$W/A' && jj --ignore-working-copy log -r 'main@git' --no-graph -T description ) | grep -q 'git-side commit'"
  integrity "$W/A"
}

# ---------------------------------------------------------------------------
# Suite: stress — 9 primary rotations with concurrent git+jj work and a
# worktree held mid-rebase throughout. Ledger files detect silent content loss.
# ---------------------------------------------------------------------------

suite_stress() {
  build
  git -C "$W/A" worktree add -q -b feat-d "$W/D"

  # Put D mid-rebase on a conflict and LEAVE it there for all 9 rounds.
  local alpha_sha
  replace alpha alpha-main "$W/A/shared.txt"; git -C "$W/A" commit -qam "main: alpha"
  alpha_sha="$(git -C "$W/A" rev-parse main)"    # D's rebase base, captured now
  replace alpha alpha-d "$W/D/shared.txt";    git -C "$W/D" commit -qam "d1: alpha"
  git -C "$W/D" rebase main > /dev/null 2>&1
  chk "setup: D is mid-rebase" "git -C '$W/D' status | grep -q 'rebase in progress'"

  # Only D's ledger is byte-asserted at the end: A/B/C become jj primaries,
  # and jj checkouts (jj new/edit) legitimately swap their working-tree
  # contents. D is never primary, so NOTHING may ever touch its files.
  local exp_D=""
  appendD() {
    echo "$1" >> "$W/D/ledger-D.txt"
    exp_D="${exp_D}$1
"
  }

  local rotation=(B C A B C A B C A)
  local r=0 target wt
  for target in "${rotation[@]}"; do
    r=$((r+1))
    echo "=== round $r: primary -> $target ==="
    SWAP_CHECK "$W/$target" "$W/A" "$W/B" "$W/C" "$W/D"

    # git work in linked (non-primary) worktrees; D only accumulates untracked.
    for wt in A B C; do
      [ "$wt" = "$target" ] && continue
      echo "round $r in $wt" >> "$W/$wt/ledger-$wt.txt"
      git -C "$W/$wt" add "ledger-$wt.txt"
      if [ $((r % 2)) -eq 1 ]; then
        git -C "$W/$wt" commit -qm "ledger $wt round $r" 2> /dev/null
      fi
    done
    appendD "round $r in D"

    # jj work in the primary
    if [ $((r % 2)) -eq 0 ]; then
      ( cd "$W/$target" && jj new -m "stress-new-r$r" ) > /dev/null 2>&1
      echo "jj payload r$r" > "$W/$target/jj-r$r.txt"
      ( cd "$W/$target" && jj status ) > /dev/null 2>&1
    else
      ( cd "$W/$target" && jj describe -m "stress-desc-r$r" ) > /dev/null 2>&1
    fi
    chk "r$r: jj op applied in $target" "( cd '$W/$target' && jj log -r @ --no-graph -T description ) | grep -q 'stress-.*-r$r'"

    # every 3rd round: create + resolve a jj conflict in the primary
    if [ $((r % 3)) -eq 0 ]; then
      ( set +o pipefail; cd "$W/$target" \
        && jj new 'main@git' -m "cfl-a-r$r" && echo a > "cfl-$r.txt" && jj status \
        && a="$(jj log -r @ --no-graph -T change_id)" \
        && jj new 'main@git' -m "cfl-b-r$r" && echo b > "cfl-$r.txt" && jj status \
        && b="$(jj log -r @ --no-graph -T change_id)" \
        && jj rebase -s "$b" -d "$a" \
        && jj log -r "$b" --no-graph | grep -qi conflict \
        && jj edit "$b" && echo ab > "cfl-$r.txt" && jj status \
        && ! (jj log -r "$b" --no-graph | grep -qi conflict) ) > "$WORK/cfl-r$r.log" 2>&1
      chk "r$r: jj conflict created+resolved in primary" "[ $? -eq 0 ]"
    fi
  done

  echo "=== finale: complete D's rebase after 9 swaps ==="
  printf 'alpha-d-resolved\nbeta\ngamma\ndelta\n' > "$W/D/shared.txt"
  ( cd "$W/D" && git add shared.txt && git rebase --continue ) > /dev/null 2>&1
  chk "finale: D rebase completed" "git -C '$W/D' log -1 --format=%s | grep -q 'd1: alpha'"
  chk "finale: D rebased onto its captured base" "git -C '$W/D' merge-base --is-ancestor '$alpha_sha' feat-d"

  echo "=== finale: bystander D's ledger byte-identical to expected ==="
  chk "ledger D intact" "[ \"\$(cat '$W/D/ledger-D.txt')\" = \"\$(printf '%s' \"$exp_D\")\" ]"

  echo "=== finale: pure swap round-trip leaves refs + object count identical ==="
  local pri="$W/A" before_refs before_objs
  before_refs="$(git -C "$pri" for-each-ref | sort)"
  before_objs="$(git -C "$pri" rev-list --all --count)"
  SP "$W/C" > /dev/null 2>&1
  SP "$W/A" > /dev/null 2>&1
  chk "refs identical after A->C->A" "[ \"\$(git -C '$pri' for-each-ref | sort)\" = \"$before_refs\" ]"
  chk "object count identical" "[ \"\$(git -C '$pri' rev-list --all --count)\" = '$before_objs' ]"
  chk "still 4 worktrees" "[ \"\$(git -C '$pri' worktree list --porcelain | grep -c '^worktree ')\" -eq 4 ]"
  integrity "$pri"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

suites=()
for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
    git | jj | stress) suites+=("$arg") ;;
    *)
      echo >&2 "error: unknown suite '$arg'"
      usage >&2
      exit 1
      ;;
  esac
done
[ "${#suites[@]}" -eq 0 ] && suites=(git jj stress)

echo "Testing recipe from: $GJF"
echo "Fixtures in: $WORK"

for suite in "${suites[@]}"; do
  suite_pass=$PASS
  suite_fail=$FAIL
  "suite_$suite"
  echo "==== $suite: $((PASS - suite_pass)) passed, $((FAIL - suite_fail)) failed ===="
done

echo
echo "==== TOTAL: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ] || exit 1
