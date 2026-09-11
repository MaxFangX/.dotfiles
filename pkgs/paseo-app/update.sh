#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash
#
# Pin the latest `maxfangx-v*` release of the Paseo fork: resolve the
# arm64 zip asset and prefetch its hash into source.json.

set -euo pipefail

OWNER="MaxFangX"
REPO="paseo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

release="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/releases/latest")"
tag="$(jq -r '.tag_name' <<< "$release")"
url="$(jq -r '.assets[]
  | select(.name | endswith("arm64.zip"))
  | .browser_download_url' <<< "$release")"

version="${tag#maxfangx-v}"

hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url "$url")")"

jq -n --arg version "$version" --arg tag "$tag" \
  --arg url "$url" --arg hash "$hash" \
  '{version: $version, tag: $tag, url: $url, hash: $hash}' \
  > "$SCRIPT_DIR/source.json"

echo "Updated paseo-app to $tag"
