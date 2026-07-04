#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="jj-vcs"
REPO="jj"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Latest release tag, e.g. "v0.43.0".
tag="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
  | jq -r '.tag_name')"
version="${tag#v}"

# Source hash: NAR hash of the unpacked tag tarball, which is
# exactly what fetchFromGitHub produces.
hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/refs/tags/$tag.tar.gz")")"

# Refresh the vendored lockfile so cargoLock.lockFile stays in
# sync with the pinned source.
curl -fsSL \
  "https://raw.githubusercontent.com/$OWNER/$REPO/$tag/Cargo.lock" \
  -o "$SCRIPT_DIR/Cargo.lock"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' \
  > "$SCRIPT_DIR/source.json"
