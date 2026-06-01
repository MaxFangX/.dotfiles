#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix nixpkgs#unzip --command bash
# shellcheck shell=bash

set -euo pipefail

BASE_URL="https://releases.omnara.com"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Release artifact for a target: macOS ships a zip'd .app
# bundle, Linux a bare binary.
artifact() {
  case "$1" in
    darwin-*) echo "omnara-$1.zip" ;;
    *) echo "omnara-$1" ;;
  esac
}

# Resolve the latest version by running the host-native binary.
# The release server exposes no version manifest, and the
# bundled JS embeds many dependency versions, so scraping the
# binary with `strings` can't be trusted.
detect_version() {
  case "$(uname -sm)" in
    "Darwin arm64")
      curl -fsSL "$BASE_URL/latest/$(artifact darwin-arm64)" \
        -o "$TMP/o.zip"
      unzip -q "$TMP/o.zip" -d "$TMP"
      OMNARA_NO_UPDATE=1 "$TMP"/*.app/Contents/MacOS/omnara --version
      ;;
    "Linux x86_64")
      curl -fsSL "$BASE_URL/latest/$(artifact linux-x64)" \
        -o "$TMP/omnara"
      chmod +x "$TMP/omnara"
      OMNARA_NO_UPDATE=1 "$TMP/omnara" --version
      ;;
    *)
      echo "unsupported host for update: $(uname -sm)" >&2
      exit 1
      ;;
  esac
}

VERSION="$(detect_version | tr -d '[:space:]')"
echo "latest omnara: $VERSION" >&2

# Pin one platform at $VERSION, emitting its sources.json entry.
# prefetch doubles as an existence check: a 404 (e.g. a platform
# not yet published at this version) aborts the whole update
# rather than writing a broken pin.
pin() {
  local nix_system="$1" target="$2"
  local url="$BASE_URL/$VERSION/$(artifact "$target")"
  echo "  $nix_system: $url" >&2
  local hash
  hash="$(nix store prefetch-file "$url" --json | jq -r .hash)"
  jq -n \
    --arg version "$VERSION" \
    --arg target "$target" \
    --arg url "$url" \
    --arg hash "$hash" \
    '{ version: $version, target: $target, url: $url, hash: $hash }'
}

LINUX="$(pin x86_64-linux linux-x64)"
DARWIN="$(pin aarch64-darwin darwin-arm64)"

jq -n --argjson linux "$LINUX" --argjson darwin "$DARWIN" \
  '{ "x86_64-linux": $linux, "aarch64-darwin": $darwin }' \
  > "$SOURCES_FILE"

echo "Updated $SOURCES_FILE" >&2
