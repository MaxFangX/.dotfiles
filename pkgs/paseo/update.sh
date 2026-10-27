#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix
#!nix nixpkgs#nodejs --command bash
# shellcheck shell=bash
#
# Pin the latest release of the Paseo fork (see default.nix): prefetch the
# macOS app zip into source.json, point package.json at the release's npm
# package tarballs, and regenerate package-lock.json. No Nix hash to
# compute for the CLI: the lockfile records each dependency's integrity
# hash, which importNpmLock uses directly.

set -euo pipefail

OWNER="MaxFangX"
REPO="paseo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

release="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/releases/latest")"
tag="$(jq -r '.tag_name' <<< "$release")"
echo "Latest fork release: $tag" >&2

# URL of the release asset whose name matches the jq regex $1.
asset_url() {
  local url
  url="$(jq -r --arg re "$1" \
    '.assets[] | select(.name | test($re)) | .browser_download_url' \
    <<< "$release")"
  [ -n "$url" ] || { echo "$tag has no asset matching $1" >&2; exit 1; }
  echo "$url"
}

app_url="$(asset_url 'arm64\.zip$')"
app_hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url "$app_url")")"

# Depend on all seven of this release's tarballs, not just the CLI's (see
# default.nix for why).
deps='{}'
for pkg in cli client highlight plugin protocol relay server; do
  url="$(asset_url "^getpaseo-$pkg-.*\\.tgz$")"
  deps="$(jq --arg name "@getpaseo/$pkg" --arg url "$url" \
    '. + {($name): $url}' <<< "$deps")"
done

jq -n --argjson deps "$deps" '{
  name: "paseo",
  private: true,
  dependencies: $deps,
  overrides: {uuid: "^11.1.1"}
}' > package.json

rm -f package-lock.json
npm install --package-lock-only --no-audit --no-fund

jq -n --arg version "${tag#maxfangx-v}" --arg tag "$tag" \
  --arg url "$app_url" --arg hash "$app_hash" \
  '{version: $version, tag: $tag, app: {url: $url, hash: $hash}}' \
  > source.json

echo "Updated paseo to $tag"
