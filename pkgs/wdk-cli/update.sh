#!/usr/bin/env nix
#!nix shell nixpkgs#jq nixpkgs#nodejs nixpkgs#curl --command bash
# shellcheck shell=bash
#
# Bump @tetherto/wdk-cli to the latest npm release and regenerate
# package-lock.json (see default.nix; the lockfile carries the hashes).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="$(curl -fsSL https://registry.npmjs.org/@tetherto/wdk-cli/latest | jq -r .version)"
echo "Latest @tetherto/wdk-cli: v$VERSION"

jq --arg v "$VERSION" \
  '.version = $v | .dependencies["@tetherto/wdk-cli"] = $v' package.json > package.json.tmp
mv package.json.tmp package.json

# --prefer-online: skip npm's metadata cache, which can lag a
# just-published version and fail resolution with ETARGET.
npm install --package-lock-only --no-audit --no-fund --prefer-online

echo "Updated wdk-cli to v$VERSION (regenerated package-lock.json)"
