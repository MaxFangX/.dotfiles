#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="MaxFangX"
REPO="jj-hunk-tool"
BRANCH="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Latest commit on the fork's default branch. Pinned by rev, not a
# release tag, since the fork has no releases.
rev="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/commits/$BRANCH" \
  | jq -r '.sha')"

# Source hash: NAR hash of the unpacked archive, which is exactly what
# fetchFromGitHub produces.
hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/$rev.tar.gz")")"

# Version from Cargo.toml at the pinned rev.
version="$(curl -fsSL \
  "https://raw.githubusercontent.com/$OWNER/$REPO/$rev/Cargo.toml" \
  | sed -n 's/^version = "\(.*\)"/\1/p' | head -1)"

# Refresh the vendored lockfile so cargoLock.lockFile stays in
# sync with the pinned source.
curl -fsSL \
  "https://raw.githubusercontent.com/$OWNER/$REPO/$rev/Cargo.lock" \
  -o "$SCRIPT_DIR/Cargo.lock"

jq -n --arg version "$version" --arg rev "$rev" --arg hash "$hash" \
  '{version: $version, rev: $rev, hash: $hash}' \
  > "$SCRIPT_DIR/source.json"
