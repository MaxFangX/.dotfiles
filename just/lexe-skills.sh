#!/usr/bin/env bash
# Diff and sync the shared agent skills between this dotfiles repo
# (ai/skills/) and the lexe monorepo (.agents/skills/).
#
# Usage:
#   lexe-skills.sh diff [skill...]
#   lexe-skills.sh sync (from-lexe|to-lexe) [skill...]
#
# Sync direction is explicit and unidirectional per invocation. A
# skill is skipped (with a warning) if its destination copy has
# uncommitted changes, so a sync can never clobber unreviewed work.
# Nothing is committed; review with git afterwards. Exits 0 with a
# note when no lexe checkout exists on this machine.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
DOT_SKILLS="$DOTFILES/ai/skills"

# Skills kept in lockstep between the two repos.
SHARED=(
  jj
  jj-rebase
  q
  tighten
  tighten-code
  tighten-comments
  codex-review
)

find_lexe() {
  local p
  for p in "$HOME/lexe/org/lexe" "$HOME/dev/lexe" "$HOME/lexe" \
    "$HOME/lexe-agent/lexe"; do
    [ -d "$p/.agents/skills" ] && { echo "$p"; return 0; }
  done
  return 1
}

usage() {
  cat >&2 << 'EOF'
Usage:
  lexe-skills.sh diff [skill...]
  lexe-skills.sh sync (from-lexe|to-lexe) [skill...]
EOF
  exit 1
}

if ! LEXE="$(find_lexe)"; then
  echo "lexe-skills: no lexe checkout found; nothing to do"
  exit 0
fi
LEXE_SKILLS="$LEXE/.agents/skills"

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
    local dot="$DOT_SKILLS/$name" lex="$LEXE_SKILLS/$name"
    if [ ! -d "$dot" ] && [ ! -d "$lex" ]; then
      echo "!! $name: missing from BOTH repos"
    elif [ ! -d "$dot" ]; then
      echo "<< $name: only in lexe (sync from-lexe to vendor)"
    elif [ ! -d "$lex" ]; then
      echo ">> $name: only in dotfiles (sync to-lexe to upstream)"
    elif ! diff -r "$dot" "$lex" > /dev/null 2>&1; then
      echo "== $name: DIFFERS"
      git diff --no-index --stat -- "$dot" "$lex" | sed 's/^/   /' \
        || true
    else
      echo "ok $name"
    fi
  done

  # Skills present on one side but not in the shared list, in case
  # something new should be adopted (lexe-specific ones excluded by
  # the shared list on purpose).
  local d
  for d in "$LEXE_SKILLS"/*/; do
    name="$(basename "$d")"
    case " ${SHARED[*]} " in *" $name "*) continue ;; esac
    echo "-- $name: in lexe only, not shared"
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

# sync (from-lexe|to-lexe) [skill...]
cmd_sync() {
  local direction="${1:-}"
  shift || true
  local src_root dst_root dst_repo
  case "$direction" in
    from-lexe)
      src_root="$LEXE_SKILLS" dst_root="$DOT_SKILLS"
      dst_repo="$DOTFILES"
      ;;
    to-lexe)
      src_root="$DOT_SKILLS" dst_root="$LEXE_SKILLS"
      dst_repo="$LEXE"
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
    if [ "$direction" = to-lexe ] \
      && [ ! -e "$LEXE/.claude/skills/$name" ]; then
      ln -s "../../.agents/skills/$name" "$LEXE/.claude/skills/$name"
      echo "link $name: created .claude/skills symlink in lexe"
    fi
  done

  if [ "${#synced[@]}" -gt 0 ]; then
    echo
    echo "Review and commit in $dst_repo:"
    local paths=("$dst_root")
    [ "$direction" = to-lexe ] && paths+=("$LEXE/.claude/skills")
    git -C "$dst_repo" status --short -- "${paths[@]}"
    if [ "$direction" = from-lexe ]; then
      echo "(run hms to apply the vendored changes)"
    fi
  fi
}

case "$cmd" in
  diff) cmd_diff "$@" ;;
  sync) cmd_sync "$@" ;;
  *) usage ;;
esac
