#!/usr/bin/env nix
#!nix shell nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash
#
# Bump @getpaseo/cli to the latest npm release and refresh the
# fixed-output hash for the *current* platform. The hash captures the
# whole resolved dependency tree, including platform-specific native
# binaries (sherpa-onnx-node), so each system needs its own entry.
#
# Same-version run: refresh only this platform's hash.
# Version bump:     drop all stored hashes (they're stale) and record
#                   this platform's new hash. Other hosts will repopulate
#                   their own entries via update.sh on their next bump.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.json"

FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
SYSTEM="$(nix eval --impure --raw --expr 'builtins.currentSystem')"

VERSION="$(curl -fsSL https://registry.npmjs.org/@getpaseo/cli/latest | jq -r .version)"
CURRENT_VERSION="$(jq -r .version "$MANIFEST")"
echo "Latest @getpaseo/cli: v$VERSION (current: v$CURRENT_VERSION, system: $SYSTEM)"

# Pin with a placeholder hash so the build is forced to re-fetch and
# report the real one. On a version bump, drop any stored per-platform
# hashes — they're for the previous version.
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
  jq --arg v "$VERSION" --arg s "$SYSTEM" --arg h "$FAKE_HASH" \
    '.version = $v | .hashes = {($s): $h}' "$MANIFEST" > "$MANIFEST.tmp"
else
  jq --arg s "$SYSTEM" --arg h "$FAKE_HASH" \
    '.hashes[$s] = $h' "$MANIFEST" > "$MANIFEST.tmp"
fi
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

jq --arg s "$SYSTEM" --arg h "$REAL_HASH" \
  '.hashes[$s] = $h' "$MANIFEST" > "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"

echo "Updated manifest.json: v$VERSION for $SYSTEM ($REAL_HASH)"
