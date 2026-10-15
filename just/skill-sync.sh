#!/usr/bin/env bash
# Diff and sync agent skills between this dotfiles repo (ai/skills/) and a
# peer repo that also carries them. Peers:
#
#   lexe   .agents/skills in the lexe monorepo. Skills written by me, kept in
#          lockstep both ways.
#   paseo  skills/ in the Paseo fork checkout. Upstream content, vendored
#          one way only: the fork rebases onto upstream, so a dotfiles-side
#          edit synced back would conflict on every release. Put additions
#          in a separate dotfiles skill instead.
#
# Usage:
#   skill-sync.sh <peer> diff [skill...]
#   skill-sync.sh <peer> sync (from|to) [skill...]
#
# Sync direction is explicit and unidirectional per invocation. A
# skill is skipped (with a warning) if its destination copy has
# uncommitted changes, so a sync can never clobber unreviewed work.
# Nothing is committed; review with git afterwards. Exits 0 with a
# note when no peer checkout exists on this machine.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
DOT_SKILLS="$DOTFILES/ai/skills"

usage() {
  cat >&2 << 'EOF'
Usage:
  skill-sync.sh <peer> diff [skill...]
  skill-sync.sh <peer> sync (from|to) [skill...]
Peers: lexe, paseo
EOF
  exit 1
}

PEER="${1:-}"
shift || true

# Per-peer config: candidate checkout roots, the skills dir inside the
# checkout, the skills kept in sync, and whether `sync to` is allowed.
case "$PEER" in
  lexe)
    ROOTS=("$HOME/lexe/org/lexe" "$HOME/dev/lexe" "$HOME/lexe" \
      "$HOME/lexe-agent/lexe")
    SKILLS_SUBDIR=.agents/skills
    SHARED=(jj jj-rebase q tighten tighten-code tighten-comments codex-review)
    ALLOW_TO=true
    ;;
  paseo)
    ROOTS=("$HOME/dev/paseo")
    SKILLS_SUBDIR=skills
    SHARED=(paseo paseo-handoff)
    ALLOW_TO=false
    ;;
  *) usage ;;
esac

find_peer() {
  local p
  for p in "${ROOTS[@]}"; do
    [ -d "$p/$SKILLS_SUBDIR" ] && { echo "$p"; return 0; }
  done
  return 1
}

if ! PEER_ROOT="$(find_peer)"; then
  echo "skill-sync: no $PEER checkout found; nothing to do"
  exit 0
fi
PEER_SKILLS="$PEER_ROOT/$SKILLS_SUBDIR"

cmd="${1:-}"
shift || true

# Skills to operate on: args after the subcommand (and direction),
# defaulting to the full shared list.
select_skills() {
  if [ "$#" -gt 0 ]; then
    SKILLS=("$@")
  else
    SKILLS=("${SHARED[@]}")
  fi
}

# diff [skill...] — show drift between the two repos.
cmd_diff() {
  select_skills "$@"
  local name
  for name in "${SKILLS[@]}"; do
    local dot="$DOT_SKILLS/$name" peer="$PEER_SKILLS/$name"
    if [ ! -d "$dot" ] && [ ! -d "$peer" ]; then
      echo "!! $name: missing from BOTH repos"
    elif [ ! -d "$dot" ]; then
      echo "<< $name: only in $PEER (sync from to vendor)"
    elif [ ! -d "$peer" ]; then
      echo ">> $name: only in dotfiles (sync to to upstream)"
    elif ! diff -r "$dot" "$peer" > /dev/null 2>&1; then
      echo "== $name: DIFFERS"
      git diff --no-index --stat -- "$dot" "$peer" | sed 's/^/   /' \
        || true
    else
      echo "ok $name"
    fi
  done

  # Skills present on one side but not in the shared list, in case
  # something new should be adopted (peer-specific ones excluded by
  # the shared list on purpose).
  local d
  for d in "$PEER_SKILLS"/*/; do
    name="$(basename "$d")"
    case " ${SHARED[*]} " in *" $name "*) continue ;; esac
    echo "-- $name: in $PEER only, not shared"
  done
  for d in "$DOT_SKILLS"/*/; do
    name="$(basename "$d")"
    case " ${SHARED[*]} " in *" $name "*) continue ;; esac
    echo "-- $name: in dotfiles only, not shared"
  done
}

# Destination path has uncommitted (staged or unstaged) changes?
dest_dirty() {
  local repo="$1" path="$2"
  [ -e "$path" ] || return 1
  [ -n "$(git -C "$repo" status --porcelain -- "$path")" ]
}

# sync (from|to) [skill...]
cmd_sync() {
  local direction="${1:-}"
  shift || true
  local src_root dst_root dst_repo
  case "$direction" in
    from | "from-$PEER")
      direction=from
      src_root="$PEER_SKILLS" dst_root="$DOT_SKILLS"
      dst_repo="$DOTFILES"
      ;;
    to | "to-$PEER")
      direction=to
      if [ "$ALLOW_TO" != true ]; then
        echo "skill-sync: $PEER skills are vendored one way; edit them" \
          "upstream or add a separate dotfiles skill" >&2
        exit 1
      fi
      src_root="$DOT_SKILLS" dst_root="$PEER_SKILLS"
      dst_repo="$PEER_ROOT"
      ;;
    *) usage ;;
  esac
  select_skills "$@"

  local name synced=()
  for name in "${SKILLS[@]}"; do
    local src="$src_root/$name" dst="$dst_root/$name"
    if [ ! -d "$src" ]; then
      echo "skip $name: not present in source"
      continue
    fi
    if diff -r "$src" "$dst" > /dev/null 2>&1; then
      echo "ok   $name: already in sync"
      continue
    fi
    if dest_dirty "$dst_repo" "$dst"; then
      echo "SKIP $name: uncommitted changes in destination —" \
        "commit or upstream them first"
      continue
    fi
    rsync -a --delete "$src/" "$dst/"
    echo "sync $name"
    synced+=("$name")

    # New skills upstreamed to lexe also need the .claude/skills
    # symlink that exposes them to Claude Code in that repo.
    if [ "$direction" = to ] && [ "$PEER" = lexe ] \
      && [ ! -e "$PEER_ROOT/.claude/skills/$name" ]; then
      ln -s "../../.agents/skills/$name" "$PEER_ROOT/.claude/skills/$name"
      echo "link $name: created .claude/skills symlink in lexe"
    fi
  done

  if [ "${#synced[@]}" -gt 0 ]; then
    echo
    echo "Review and commit in $dst_repo:"
    local paths=("$dst_root")
    [ "$direction" = to ] && paths+=("$PEER_ROOT/.claude/skills")
    git -C "$dst_repo" status --short -- "${paths[@]}"
    if [ "$direction" = from ]; then
      echo "(run hms to apply the vendored changes)"
    fi
  fi
}

case "$cmd" in
  diff) cmd_diff "$@" ;;
  sync) cmd_sync "$@" ;;
  *) usage ;;
esac
