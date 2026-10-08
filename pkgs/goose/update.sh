#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

# Fetch latest version from GitHub releases
VERSION=$(
  curl -s \
    "https://api.github.com/repos/aaif-goose/goose/releases/latest" \
    | jq -r '.tag_name | ltrimstr("v")'
)
echo "Latest version: $VERSION" >&2

prefetch_hash() {
  local target=$1
  local url="https://github.com/aaif-goose/goose/releases/download/v${VERSION}/goose-${target}.tar.gz"
  echo "Prefetching $target..." >&2
  nix store prefetch-file "$url" --json | jq -r '.hash'
}

X86_64_HASH=$(prefetch_hash "x86_64-unknown-linux-gnu")
AARCH64_LINUX_HASH=$(prefetch_hash "aarch64-unknown-linux-gnu")
DARWIN_HASH=$(prefetch_hash "aarch64-apple-darwin")

jq -n \
  --arg version "$VERSION" \
  --arg x86_64_hash "$X86_64_HASH" \
  --arg aarch64_linux_hash "$AARCH64_LINUX_HASH" \
  --arg darwin_hash "$DARWIN_HASH" \
  '{
    version: $version,
    "x86_64-linux": {
      url: "https://github.com/aaif-goose/goose/releases/download/v\($version)/goose-x86_64-unknown-linux-gnu.tar.gz",
      hash: $x86_64_hash
    },
    "aarch64-linux": {
      url: "https://github.com/aaif-goose/goose/releases/download/v\($version)/goose-aarch64-unknown-linux-gnu.tar.gz",
      hash: $aarch64_linux_hash
    },
    "aarch64-darwin": {
      url: "https://github.com/aaif-goose/goose/releases/download/v\($version)/goose-aarch64-apple-darwin.tar.gz",
      hash: $darwin_hash
    }
  }' > "$SOURCES_FILE"

echo "Updated $SOURCES_FILE to version $VERSION"
