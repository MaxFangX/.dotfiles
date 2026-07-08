#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq nixpkgs#nix --command bash
# shellcheck shell=bash

set -euo pipefail

OWNER="jj-vcs"
REPO="jj"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Temporarily tracking the head of jj-vcs/jj#8667 (compatibility
# with git worktrees) instead of the latest release tag. When the
# PR merges, uncomment the release-tag block and delete the
# PR-branch block; everything else works unchanged for both.

# Version from Cargo.toml at the pinned rev, e.g. "0.44.0".

# Release tag: latest release, e.g. "v0.43.0".
# tag="$(curl -fsSL \
#   "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
#   | jq -r '.tag_name')"
# rev="$tag"
# version="${tag#v}"

# PR branch: latest commit, with version from its Cargo.toml
# (e.g. "0.41.0" -- the version the branch was last rebased onto).
BRANCH="colocated-workspaces"
rev="$(curl -fsSL \
  "https://api.github.com/repos/$OWNER/$REPO/commits/$BRANCH" \
  | jq -r '.sha')"

# Version from Cargo.toml at the pinned rev, e.g. "0.44.0".
version="$(curl -fsSL \
  "https://raw.githubusercontent.com/$OWNER/$REPO/$rev/Cargo.toml" \
  | sed -n 's/^version = "\(.*\)"/\1/p' | head -1)"

# Source hash: NAR hash of the unpacked archive, which is exactly
# what fetchFromGitHub produces.
hash="$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack \
    "https://github.com/$OWNER/$REPO/archive/$rev.tar.gz")")"

# Refresh the vendored lockfile so cargoLock.lockFile stays in
# sync with the pinned source.
curl -fsSL \
  "https://raw.githubusercontent.com/$OWNER/$REPO/$rev/Cargo.lock" \
  -o "$SCRIPT_DIR/Cargo.lock"

jq -n --arg version "$version" --arg rev "$rev" --arg hash "$hash" \
  '{version: $version, rev: $rev, hash: $hash}' \
  > "$SCRIPT_DIR/source.json"
