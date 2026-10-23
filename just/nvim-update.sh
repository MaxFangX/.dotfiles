#!/usr/bin/env bash
# Update lazy.nvim plugins and copy the resulting lockfile over the
# tracked nvim/lazy-lock.json (see nvim/lua/config/lazy.lua).
set -euo pipefail
cd "$(dirname "$0")/.."

lock="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lazy/lazy-lock.json"
# A Lua error leaves headless nvim waiting for input, so `cquit` follows.
LAZY_QUIET=1 nvim --headless "+lua require('lazy_headless').update()" \
  "+cquit 1"
cp "$lock" nvim/lazy-lock.json
git diff --stat -- nvim/lazy-lock.json
