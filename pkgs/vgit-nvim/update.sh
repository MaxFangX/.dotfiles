#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="maxfangx"
REPO="vgit.nvim"
BRANCH="main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Latest commit on the fork's default branch. Pinned by rev, not a
# release tag, since the fork has no releases.
commit="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/commits/$BRANCH")"
rev="$(jq -r '.sha' <<< "$commit")"

# The plugin has no version of its own, so follow nixpkgs' convention
# for unreleased software: 0-unstable-<commit date>.
version="0-unstable-$(jq -r '.commit.committer.date[:10]' <<< "$commit")"

# Source hash: NAR hash of the unpacked archive, which is exactly what
# fetchFromGitHub produces.
hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/$rev.tar.gz")")"

jq -n --arg version "$version" --arg rev "$rev" --arg hash "$hash" \
  '{version: $version, rev: $rev, hash: $hash}' \
  > "$SCRIPT_DIR/source.json"
