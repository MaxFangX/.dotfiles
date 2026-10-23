#!/usr/bin/env bash
set -euo pipefail

# Write the `claude-confidential` Paseo provider (see confidential.nix)
# into ~/.paseo/config.json. Runs on home-manager activation. The JSON
# is merged key by key, so re-running is safe.
#
# Env:
#   PASEO_BIN  paseo binary, used to reload the daemon if one is running
#   WRAPPER    absolute path of the claude-confidential wrapper

env_file="$HOME/env/sensitive.sh"
# shellcheck disable=SC1090
[ -f "$env_file" ] && . "$env_file"
tinfoil_key="${TINFOIL_API_KEY:-}"
if [ -z "$tinfoil_key" ]; then
  echo "confidential-sync: TINFOIL_API_KEY not set in $env_file; skipping"
  exit 0
fi

paseo_home="${PASEO_HOME:-$HOME/.paseo}"
paseo_cfg="$paseo_home/config.json"
mkdir -p "$paseo_home"
[ -s "$paseo_cfg" ] || echo '{ "version": 1 }' > "$paseo_cfg"

# Paseo passes provider env literally, so the key is written in.
# `models` replaces the inherited Claude list. The Tinfoil entry keeps a
# Claude ID: any name reaches the router's default route, and a 1M one
# makes Claude Code's context accounting match DeepSeek's window.
tmp=$(mktemp)
jq --indent 2 --arg tinfoil "$tinfoil_key" --arg wrapper "$WRAPPER" '
  .agents.providers."claude-confidential" = {
    extends: "claude",
    label: "Claude Code (confidential)",
    description: ("Claude Code on DeepSeek V4.1 Flash inside Tinfoil and "
      + "Maple enclaves, via claude-code-router"),
    command: [$wrapper],
    env: { TINFOIL_API_KEY: $tinfoil },
    models: [
      { id: "opus[1m]", label: "DeepSeek V4.1 Flash (Tinfoil)" },
      { id: "maple,deepseek-v4-1-flash",
        label: "DeepSeek V4.1 Flash (Maple)" },
      { id: "maple,deepseek-v4-1-flash-1017-uncensored",
        label: "DeepSeek V4.1 Flash Uncensored (Maple)" }
    ]
  }
' "$paseo_cfg" > "$tmp"
mv "$tmp" "$paseo_cfg"

# Pick up the provider changes if a daemon is running.
timeout 10 "$PASEO_BIN" reload > /dev/null 2>&1 || true
