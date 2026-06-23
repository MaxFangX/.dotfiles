#!/usr/bin/env nix
#!nix shell nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash
#
# Bump @getpaseo/cli to the latest npm release and refresh the
# fixed-output hash. Because the hash captures the whole resolved
# dependency tree, we can't precompute it — we pin the version with a
# fake hash, let `nix build` report the real one, then write it back.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.json"

FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

VERSION="$(curl -fsSL https://registry.npmjs.org/@getpaseo/cli/latest | jq -r .version)"
echo "Latest @getpaseo/cli: v$VERSION"

# Pin the version with a placeholder hash so the build is forced to
# re-fetch and report the real one.
jq --arg v "$VERSION" --arg h "$FAKE_HASH" \
  '.version = $v | .hash = $h' "$MANIFEST" > "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"

echo "Computing fixed-output hash (this downloads the package)..."
build_log="$(nix build -f "$DOTFILES_DIR" paseo --no-link 2>&1 || true)"

REAL_HASH="$(echo "$build_log" | awk '/got:/ { print $NF; exit }')"
if [ -z "$REAL_HASH" ]; then
  if echo "$build_log" | grep -q "specified: $FAKE_HASH"; then
    echo "Build produced no 'got:' hash. Full log:" >&2
    echo "$build_log" >&2
    exit 1
  fi
  # No mismatch reported — the fake hash somehow matched (impossible)
  # or the build already succeeded with a stale-but-correct hash.
  echo "Could not extract a new hash; manifest left pinned to v$VERSION." >&2
  echo "$build_log" >&2
  exit 1
fi

jq --arg h "$REAL_HASH" '.hash = $h' "$MANIFEST" > "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"

echo "Updated manifest.json to v$VERSION ($REAL_HASH)"
