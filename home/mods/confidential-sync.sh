#!/usr/bin/env bash
set -euo pipefail

# Wire TINFOIL_API_KEY and MAPLE_API_KEY into the Paseo config. See
# confidential.nix for the design. Runs on home-manager activation. The
# JSON is merged key by key, so re-running is safe.
#
# Env:
#   PASEO_BIN  paseo binary, used to reload the daemon if one is running

env_file="$HOME/env/sensitive.sh"
# shellcheck disable=SC1090
[ -f "$env_file" ] && . "$env_file"
tinfoil_key="${TINFOIL_API_KEY:-}"
maple_key="${MAPLE_API_KEY:-}"
if [ -z "$tinfoil_key" ] && [ -z "$maple_key" ]; then
  echo "confidential-sync: no TINFOIL_API_KEY or MAPLE_API_KEY in" \
    "$env_file; skipping"
  exit 0
fi

router_url="http://127.0.0.1:3456"
paseo_home="${PASEO_HOME:-$HOME/.paseo}"

###############
# Paseo       #
###############

# The Maple key is the `claude-deepseek` provider's router token (see
# maple.nix). That provider inherits Claude's model list, all of which
# route to the default DeepSeek, so the uncensored variant is an extra
# named entry. Nonessential traffic is off there, so the proxy is the
# session's only outbound connection.
paseo_cfg="$paseo_home/config.json"
mkdir -p "$paseo_home"
[ -s "$paseo_cfg" ] || echo '{ "version": 1 }' > "$paseo_cfg"
tmp=$(mktemp)
jq --indent 2 --arg maple "$maple_key" --arg router "$router_url" '
  if $maple != "" then
      .agents.providers."claude-deepseek" = {
        extends: "claude",
        label: "Claude Code / DeepSeek V4.1 Flash (Maple)",
        description: ("Claude Code on DeepSeek V4.1 Flash through "
          + "claude-code-router and the Maple proxy (confidential)"),
        env: {
          ANTHROPIC_BASE_URL: $router,
          ANTHROPIC_AUTH_TOKEN: $maple,
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
        },
        additionalModels: [{
          id: "maple,deepseek-v4-1-flash-1017-uncensored",
          label: "DeepSeek V4.1 Flash Uncensored"
        }]
      }
    else . end
' "$paseo_cfg" > "$tmp"
mv "$tmp" "$paseo_cfg"

# Pick up the provider changes if a daemon is running.
timeout 10 "$PASEO_BIN" reload > /dev/null 2>&1 || true
