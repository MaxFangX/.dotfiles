#!/usr/bin/env nix
#!nix shell nixpkgs#jq nixpkgs#nodejs nixpkgs#curl --command bash
# shellcheck shell=bash
#
# Bump @getpaseo/cli to the latest npm release and regenerate
# package-lock.json. No Nix hash to compute: the lockfile records each
# dependency's integrity hash, which importNpmLock uses directly (see
# default.nix).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="$(curl -fsSL https://registry.npmjs.org/@getpaseo/cli/latest | jq -r .version)"
echo "Latest @getpaseo/cli: v$VERSION"

jq --arg v "$VERSION" \
  '.version = $v | .dependencies["@getpaseo/cli"] = $v' package.json > package.json.tmp
mv package.json.tmp package.json

npm install --package-lock-only --no-audit --no-fund

echo "Updated paseo to v$VERSION (regenerated package-lock.json)"
