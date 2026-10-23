#!/usr/bin/env bash
set -euo pipefail

# Wire TINFOIL_API_KEY and MAPLE_API_KEY into the kimi and Paseo configs.
# See confidential.nix for the design. Runs on home-manager activation.
# The kimi TOML gets one marker-delimited block replaced in place and the
# Paseo JSON is merged key by key, so re-running is safe.
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

tinfoil_url="http://127.0.0.1:3301/v1"
maple_url="http://127.0.0.1:3302/v1"
router_url="http://127.0.0.1:3456"
kimi_home="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
paseo_home="${PASEO_HOME:-$HOME/.paseo}"

# Replace the managed block in $1 with stdin, appending it if absent.
splice_block() {
  local file=$1
  local begin="# >>> kimi (managed by dotfiles) >>>"
  local end="# <<< kimi <<<"
  local block tmp
  block=$(cat)
  tmp=$(mktemp)

  mkdir -p "$(dirname "$file")"
  touch "$file"
  # Drop the old block and any trailing blank lines, then append.
  awk -v b="$begin" -v e="$end" '$0 == b { skip = 1 } !skip { print }
    $0 == e { skip = 0 }' "$file" \
    | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$tmp"
  [ -s "$tmp" ] && echo >> "$tmp"
  printf '%s\n%s\n%s\n' "$begin" "$block" "$end" >> "$tmp"
  mv "$tmp" "$file"
}

# Set the top-level `key = "value"` in the kimi TOML, which must precede
# any table.
set_toplevel() {
  local file=$1 key=$2 value=$3
  if grep -q "^$key = " "$file"; then
    sed -i "s|^$key = .*|$key = \"$value\"|" "$file"
  else
    printf '%s = "%s"\n\n' "$key" "$value" \
      | cat - "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

###############
# kimi CLI    #
###############

# The kimi model alias `maple/$1`, displayed as `$2`.
maple_model() {
  cat <<EOT

[models."maple/$1"]
provider = "maple"
model = "$1"
max_context_size = 1048576
max_output_size = 131072
capabilities = [ "image_in", "thinking", "tool_use" ]
display_name = "$2 (Maple, confidential)"
support_efforts = [ "low", "high", "xhigh", "max" ]
off_effort = "none"
EOT
}

# One provider block per key present.
kimi_cfg="$kimi_home/config.toml"
{
  [ -n "$tinfoil_key" ] && cat <<EOT
[providers.tinfoil]
type = "openai"
base_url = "$tinfoil_url"
api_key_env = "TINFOIL_API_KEY"

[models."tinfoil/kimi-k3"]
provider = "tinfoil"
model = "kimi-k3"
max_context_size = 262144
max_output_size = 262144
capabilities = [ "image_in", "always_thinking", "tool_use" ]
display_name = "Kimi K3 (Tinfoil, confidential)"
EOT
  [ -n "$tinfoil_key" ] && [ -n "$maple_key" ] && echo
  if [ -n "$maple_key" ]; then
    cat <<EOT
[providers.maple]
type = "openai"
base_url = "$maple_url"
api_key_env = "MAPLE_API_KEY"
EOT
    maple_model deepseek-v4-1-flash "DeepSeek V4.1 Flash"
    maple_model deepseek-v4-1-flash-1017-uncensored \
      "DeepSeek V4.1 Flash Uncensored"
  fi
} | splice_block "$kimi_cfg"
if [ -n "$tinfoil_key" ]; then
  set_toplevel "$kimi_cfg" default_model tinfoil/kimi-k3
else
  set_toplevel "$kimi_cfg" default_model maple/deepseek-v4-1-flash
fi

###############
# Paseo       #
###############

# The keys go in the kimi and opencode provider envs (see
# confidential.nix). The Maple key is also the `claude-deepseek`
# provider's router token (see maple.nix). That provider inherits
# Claude's model list, all of which route to the default DeepSeek, so
# the uncensored variant is an extra named entry. Nonessential traffic
# is off there, so the proxy is the session's only outbound connection.
paseo_cfg="$paseo_home/config.json"
mkdir -p "$paseo_home"
[ -s "$paseo_cfg" ] || echo '{ "version": 1 }' > "$paseo_cfg"
tmp=$(mktemp)
jq --indent 2 \
  --arg tinfoil "$tinfoil_key" --arg maple "$maple_key" \
  --arg router "$router_url" '
  # Only the keys we have, so a missing key never blanks a present one.
  ({ TINFOIL_API_KEY: $tinfoil, MAPLE_API_KEY: $maple }
    | with_entries(select(.value != ""))) as $keys
  | .agents.providers.kimi |= (
    (. // { extends: "acp", label: "Kimi Code CLI",
            command: ["kimi", "acp"] })
    | .env += $keys
  )
  | .agents.providers.opencode.env += $keys
  | if $maple != "" then
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
