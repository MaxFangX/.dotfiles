#!/usr/bin/env nix
#!nix shell nixpkgs#jq nixpkgs#nodejs nixpkgs#curl --command bash
# shellcheck shell=bash
#
# Bump @zed-industries/claude-agent-acp to the latest npm release and
# regenerate package-lock.json. No Nix hash to compute: the lockfile
# records each dependency's integrity hash, which importNpmLock uses
# directly (see default.nix).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PKG="@zed-industries/claude-agent-acp"
VERSION="$(curl -fsSL "https://registry.npmjs.org/$PKG/latest" \
  | jq -r .version)"
echo "Latest $PKG: v$VERSION"

jq --arg v "$VERSION" --arg pkg "$PKG" \
  '.version = $v | .dependencies[$pkg] = $v' package.json > package.json.tmp
mv package.json.tmp package.json

npm install --package-lock-only --no-audit --no-fund

echo "Updated claude-agent-acp to v$VERSION (regenerated package-lock.json)"
