#!/usr/bin/env nix
#!nix shell nixpkgs#nix-update --command bash
# shellcheck shell=bash
#
# Bump buzz to the tip of the pinned fork branch (see the TODO in
# default.nix). nix-update rewrites the version and src hash in default.nix,
# plus each subpackage's dependency hash (frontend pnpmDeps, sidecars/desktop
# cargoHash).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.."

# TODO(max): Once back on block/buzz release tags, drop the branch pin
# (and the version fixup below) in favor of --version-regex
# 'desktop-v(.*)' — releases are tagged desktop-vX.Y.Z.
nix-update buzz \
  --version=branch=codex/bolt12-wallet-mvp \
  --subpackage frontend \
  --subpackage sidecars \
  --subpackage desktop

# Branch mode labels the version after the fork's latest release tag,
# which is unrelated (e.g. sprout-agent-bundle-latest), and
# --version-regex can only filter those same tag-derived candidates.
# Instead, rewrite the prefix to the app's own version at the pinned
# rev, keeping nix-update's -unstable-<date> suffix.
raw_url="https://raw.githubusercontent.com/benthecarman/buzz"
rev=$(sed -n 's/^ *rev = "\(.*\)";/\1/p' pkgs/buzz/default.nix)
app_version=$(
  curl -fsSL "$raw_url/$rev/desktop/src-tauri/tauri.conf.json" |
    sed -n 's/^ *"version": "\([^"]*\)".*/\1/p'
)
sed -i.bak -E \
  "s/^( *version = )\".*-(unstable-[0-9-]+)\";/\1\"$app_version-\2\";/" \
  pkgs/buzz/default.nix
rm pkgs/buzz/default.nix.bak

grep -m1 'version = ' pkgs/buzz/default.nix
