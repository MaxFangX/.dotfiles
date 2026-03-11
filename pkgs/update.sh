#!/usr/bin/env bash
set -euo pipefail

packages_json="$1"

GREEN=$'\033[32m'
RED=$'\033[31m'
RESET=$'\033[0m'

declare -a failed=()
ok=0
total=$(jq 'length' "$packages_json")
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

get_version() {
  nix eval -f . --raw "\"$1\".version" 2>/dev/null \
    || echo "?"
}

while read -r pkg; do
  name=$(echo "$pkg" | jq -r '.name')
  pname=$(echo "$pkg" | jq -r '.pname')
  old=$(echo "$pkg" | jq -r '.oldVersion')
  mapfile -t cmd < <(echo "$pkg" | jq -r '.updateScript[]')

  if "${cmd[@]}" > "$tmp" 2>&1; then
    new=$(get_version "$name")
    if [[ "$old" == "$new" ]]; then
      echo "${GREEN}ok${RESET} $pname: $old (unchanged)"
    else
      echo "${GREEN}ok${RESET} $pname: $old -> $new"
    fi
    ((ok++)) || true
  else
    echo "${RED}FAIL${RESET} $pname"
    cat "$tmp"
    echo
    failed+=("$pname")
  fi
done < <(jq -c '.[]' "$packages_json")

# Summary
if [[ $total -gt 1 || ${#failed[@]} -gt 0 ]]; then
  echo
  if [[ ${#failed[@]} -eq 0 ]]; then
    echo "Updated $ok/$total packages"
  else
    echo "Updated $ok/$total, failed: ${failed[*]}"
  fi
fi
