#!/usr/bin/env bash
set -euo pipefail

# Merge MCP servers into ~/.claude.json. Claude Code rewrites that file
# freely, so each named entry is replaced whole and the rest left alone.
# See claude-mcp.nix.
#
# CLAUDE_MCP_SERVERS: JSON file of servers from nix. A string value may
# reference a credential as `$VAR`, filled in from ~/env/sensitive.sh,
# and a server whose variable is unset is skipped.
# CLAUDE_MCP_ON_DEMAND: JSON array of servers to disable in every project.

env_file="$HOME/env/sensitive.sh"
# shellcheck disable=SC1090
[ -f "$env_file" ] && . "$env_file"

cfg="$HOME/.claude.json"
[ -s "$cfg" ] || echo '{}' > "$cfg"

# Merge the JSON object on stdin into .mcpServers.
merge_servers() {
  local tmp
  tmp=$(mktemp)
  jq --indent 2 --argjson s "$(cat)" '.mcpServers += $s' "$cfg" > "$tmp"
  mv "$tmp" "$cfg"
}

jq -c 'to_entries[]' "$CLAUDE_MCP_SERVERS" | while read -r entry; do
  name=$(jq -r .key <<<"$entry")
  server=$(jq -c .value <<<"$entry")

  # Credential references anywhere in the entry's JSON text.
  mapfile -t vars < <(grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' <<<"$server" \
    | tr -d '$' | sort -u || true)

  skip=
  for var in "${vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      echo "claude-mcp-sync: $name: $var not set in $env_file; skipping"
      skip=1
    fi
  done
  if [ -n "$skip" ]; then continue; fi

  # Fill in each reference. `\b` keeps `$FOO` from matching in `$FOOBAR`.
  for var in "${vars[@]}"; do
    server=$(jq -c --arg var "$var" --arg val "${!var}" \
      'walk(if type == "string" then gsub("\\$\($var)\\b"; $val) else . end)' \
      <<<"$server")
  done
  jq -n --arg name "$name" --argjson server "$server" '{($name): $server}' \
    | merge_servers
done

# Disable the on-demand servers in every project, and re-enable any
# declared server that is no longer on-demand. Servers not declared here
# (e.g. toggled off by hand in /mcp) are left as they are.
on_demand="${CLAUDE_MCP_ON_DEMAND:-[]}"
declared="$(jq -c 'keys' "$CLAUDE_MCP_SERVERS")"
tmp=$(mktemp)
jq --indent 2 --argjson on "$on_demand" --argjson declared "$declared" '
  .projects |= with_entries(.value.disabledMcpServers |=
    ((. // []) - ($declared - $on) + $on | unique))
' "$cfg" > "$tmp"
mv "$tmp" "$cfg"
