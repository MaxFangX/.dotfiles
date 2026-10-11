#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="tinfoilsh"
REPO="tinfoil-proxy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/source.json"

# Latest release tag, e.g. "v0.2.3".
tag="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
  | jq -r '.tag_name')"
version="${tag#v}"
echo "Latest version: $version" >&2

# Source hash: NAR hash of the unpacked tag tarball, which is
# exactly what fetchFromGitHub produces.
hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/refs/tags/$tag.tar.gz")")"

# Vendor hash: write a placeholder, let the build fail on the mismatch,
# and take the hash it reports. The build is expected to fail, so
# capture its output before parsing rather than piping under pipefail.
write_source() {
  jq -n --arg version "$version" --arg hash "$hash" --arg vendor "$1" \
    '{version: $version, hash: $hash, vendorHash: $vendor}' \
    > "$SOURCE_FILE"
}
write_source "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
echo "Computing vendorHash..." >&2
build_log="$(nix build -f "$SCRIPT_DIR/../.." tinfoil-proxy --no-link 2>&1 \
  || true)"
vendor="$(printf '%s\n' "$build_log" | awk '/got:/ { print $2; exit }')"
[ -n "$vendor" ] || { echo "Could not determine vendorHash" >&2; exit 1; }
write_source "$vendor"

echo "Updated $SOURCE_FILE to version $version"
