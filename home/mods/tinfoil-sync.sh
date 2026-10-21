#!/usr/bin/env bash
set -euo pipefail

# Wire TINFOIL_API_KEY into the kimi and Paseo configs. See tinfoil.nix for
# the design. Run on home-manager activation and
# safe to re-run: the kimi TOML gets one marker-delimited block that is
# replaced in place, and the Paseo JSON is merged key by key.
#
# Env:
#   PASEO_BIN  paseo binary, used to reload the daemon if one is running

env_file="$HOME/env/sensitive.sh"
# shellcheck disable=SC1090
[ -f "$env_file" ] && . "$env_file"
tinfoil_key="${TINFOIL_API_KEY:-}"
if [ -z "$tinfoil_key" ]; then
  echo "tinfoil-sync: TINFOIL_API_KEY not set in $env_file; skipping"
  exit 0
fi

tinfoil_url="http://127.0.0.1:3301/v1"
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

kimi_cfg="$kimi_home/config.toml"
splice_block "$kimi_cfg" <<EOF
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
EOF
set_toplevel "$kimi_cfg" default_model tinfoil/kimi-k3

###############
# Paseo       #
###############

# The key goes in the ACP kimi provider's env so `api_key_env` resolves
# when the daemon spawns `kimi acp`, and in the built-in opencode
# provider's env for opencode.json's `{env:TINFOIL_API_KEY}`.
paseo_cfg="$paseo_home/config.json"
mkdir -p "$paseo_home"
[ -s "$paseo_cfg" ] || echo '{ "version": 1 }' > "$paseo_cfg"
tmp=$(mktemp)
jq --indent 2 --arg key "$tinfoil_key" '
  .agents.providers.kimi |= (
    (. // { extends: "acp", label: "Kimi Code CLI",
            command: ["kimi", "acp"] })
    | .env.TINFOIL_API_KEY = $key
  )
  | .agents.providers.opencode.env.TINFOIL_API_KEY = $key
' "$paseo_cfg" > "$tmp"
mv "$tmp" "$paseo_cfg"

# Pick up the provider changes if a daemon is running.
timeout 10 "$PASEO_BIN" reload > /dev/null 2>&1 || true
