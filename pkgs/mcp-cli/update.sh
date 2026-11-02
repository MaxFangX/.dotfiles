#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="tkukushkin"
REPO="mcp-cli"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/source.json"

# Upstream publishes no releases, so pin the tip of main.
commit="$(curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/commits/main")"
rev="$(jq -r '.sha' <<<"$commit")"
date="$(jq -r '.commit.committer.date[:10]' <<<"$commit")"
echo "Latest commit: $rev ($date)" >&2

hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/$rev.tar.gz")")"

# Vendor hash: write a placeholder, let the build fail on the mismatch,
# and take the hash it reports.
write_source() {
  jq -n --arg rev "$rev" --arg date "$date" --arg hash "$hash" \
    --arg vendor "$1" \
    '{rev: $rev, date: $date, hash: $hash, vendorHash: $vendor}' \
    > "$SOURCE_FILE"
}
write_source "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
echo "Computing vendorHash..." >&2
build_log="$(nix build -f "$SCRIPT_DIR/../.." mcp-cli --no-link 2>&1 \
  || true)"
vendor="$(printf '%s\n' "$build_log" | awk '/got:/ { print $2; exit }')"
[ -n "$vendor" ] || { echo "Could not determine vendorHash" >&2; exit 1; }
write_source "$vendor"

echo "Updated $SOURCE_FILE to $rev ($date)"
