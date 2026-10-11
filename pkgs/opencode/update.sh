#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.json"
REPO="https://github.com/anomalyco/opencode"
API="https://api.github.com/repos/anomalyco/opencode"

VERSION=$(
  curl -s "$API/releases/latest" | jq -r '.tag_name | ltrimstr("v")'
)
echo "Latest version: $VERSION" >&2

# Emit the {url, hash} object for one release asset.
source_for() {
  local asset="opencode-$1"
  local url="$REPO/releases/download/v$VERSION/$asset"
  echo "Prefetching $asset..." >&2
  jq -n --arg url "$url" \
    --arg hash "$(nix store prefetch-file "$url" --json | jq -r .hash)" \
    '{ url: $url, hash: $hash }'
}

jq -n \
  --arg version "$VERSION" \
  --argjson x86_64_linux "$(source_for linux-x64.tar.gz)" \
  --argjson aarch64_linux "$(source_for linux-arm64.tar.gz)" \
  --argjson aarch64_darwin "$(source_for darwin-arm64.zip)" \
  '{
    version: $version,
    "x86_64-linux": $x86_64_linux,
    "aarch64-linux": $aarch64_linux,
    "aarch64-darwin": $aarch64_darwin
  }' > "$SOURCES_FILE"

echo "Updated $SOURCES_FILE to version $VERSION"
