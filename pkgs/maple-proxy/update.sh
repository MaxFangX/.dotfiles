#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="MaplePrivacyLabs"
REPO="Maple"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/source.json"
PLACEHOLDER="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# The proxy has no release of its own and ships with the app release, so
# take the latest Maple tag, e.g. "v3.4.4".
tag="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
  | jq -r '.tag_name')"
version="${tag#v}"
echo "Latest version: $version" >&2

write_source() {
  jq -n --arg version "$version" --arg hash "$1" --arg cargo "$2" \
    '{version: $version, hash: $hash, cargoHash: $cargo}' \
    > "$SOURCE_FILE"
}

# The source is a sparse checkout, so nix-prefetch-url can't hash it.
# Instead both hashes come from a failing build: write a placeholder, let
# the build fail on the mismatch, and take the hash it reports. The build
# is expected to fail, so capture its output before parsing rather than
# piping under pipefail.
reported_hash() {
  local build_log
  build_log="$(nix build -f "$SCRIPT_DIR/../.." maple-proxy --no-link 2>&1 \
    || true)"
  printf '%s\n' "$build_log" | awk '/got:/ { print $2; exit }'
}

write_source "$PLACEHOLDER" "$PLACEHOLDER"
echo "Computing source hash..." >&2
hash="$(reported_hash)"
[ -n "$hash" ] || { echo "Could not determine source hash" >&2; exit 1; }

write_source "$hash" "$PLACEHOLDER"
echo "Computing cargoHash..." >&2
cargo="$(reported_hash)"
[ -n "$cargo" ] || { echo "Could not determine cargoHash" >&2; exit 1; }
write_source "$hash" "$cargo"

echo "Updated $SOURCE_FILE to version $version"
