#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq --command bash
# shellcheck shell=bash
#
# Pull the latest release manifest. It already carries the version,
# tag, and sha256 of every platform zip, so there is no Nix hash to
# prefetch (see default.nix).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.json"
LATEST="https://github.com/MoonshotAI/kimi-code/releases/latest"

curl -fsSL "$LATEST/download/manifest.json" -o "$MANIFEST"

echo "Updated manifest.json to v$(jq -r .version "$MANIFEST")"
