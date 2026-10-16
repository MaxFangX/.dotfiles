#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

REPO="vercel-labs/agent-browser"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

# Fetch latest version from GitHub releases
VERSION=$(
  curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | jq -r '.tag_name | ltrimstr("v")'
)
echo "Latest version: $VERSION" >&2

# fetchFromGitHub's hash: the NAR hash of the unpacked tag tarball.
echo "Prefetching source..." >&2
SRC_HASH=$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$REPO/archive/refs/tags/v$VERSION.tar.gz")")

# Print the sources.json entry for one release asset.
platform_source() {
  local asset=$1
  local url="https://github.com/$REPO/releases/download/v$VERSION/agent-browser-$asset"
  echo "Prefetching $asset..." >&2
  nix store prefetch-file "$url" --json \
    | jq --arg url "$url" '{ url: $url, hash: .hash }'
}

X86_64_LINUX=$(platform_source "linux-musl-x64")
AARCH64_LINUX=$(platform_source "linux-musl-arm64")
X86_64_DARWIN=$(platform_source "darwin-x64")
AARCH64_DARWIN=$(platform_source "darwin-arm64")

jq -n \
  --arg version "$VERSION" \
  --arg src_hash "$SRC_HASH" \
  --argjson x86_64_linux "$X86_64_LINUX" \
  --argjson aarch64_linux "$AARCH64_LINUX" \
  --argjson x86_64_darwin "$X86_64_DARWIN" \
  --argjson aarch64_darwin "$AARCH64_DARWIN" \
  '{
    version: $version,
    srcHash: $src_hash,
    "x86_64-linux": $x86_64_linux,
    "aarch64-linux": $aarch64_linux,
    "x86_64-darwin": $x86_64_darwin,
    "aarch64-darwin": $aarch64_darwin
  }' > "$SOURCES_FILE"

echo "Updated $SOURCES_FILE to version $VERSION"
