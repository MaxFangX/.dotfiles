#!/usr/bin/env bash
set -euo pipefail

# # clean
#
# Frees disk space by deleting data that is regenerated on demand. Each
# section has its own age threshold, chosen so that the defaults are always
# safe; pass `days` to override (0 = hard clean). `mod.just` composes them.
#
# ## Usage
#
# clean.sh <section> [days]
#
# ## Args
#
# section = nix | build | caches | rust | ios
# days    = Age threshold overriding the section default: entries untouched
#           for longer than this are deleted. Section defaults:
#             nix    30  Home Manager / profile generations
#             build   0  Cargo, npm, Flutter build output dirs
#             rust    7  rustup toolchains (per binary atime)
#             ios    30  Xcode iOS DeviceSupport entries
#           `caches` deletes unconditionally.

section="${1:?usage: clean.sh <section> [days]}"
days="${2:-}"

remove() {
  for path in "$@"; do
    [[ -e $path ]] || continue
    echo "rm $path"
    # Some build output (e.g. Flutter.framework in DerivedData) is read-only
    rm -rf "$path" 2>/dev/null || { chmod -R u+w "$path" && rm -rf "$path"; }
  done
}

clean_nix() {
  local days="${1:-30}"
  echo "==> Nix (generations older than $days days)"
  home-manager expire-generations "-$days days"
  nix profile wipe-history --older-than "${days}d"
  nix store gc
}

# Delete build output dirs (identified by marker files) with no entries
# modified within `days`
clean_build() {
  local days="${1:-0}"
  echo "==> Build output (untouched for $days days)"
  while IFS= read -r -d '' dir; do
    name=${dir##*/}
    case "$name" in
      # Cargo tags target dirs it creates itself; ones pre-created by scripts
      # (e.g. lexe's CARGO_TARGET_DIR) only have the profile dirs' lock files
      target)
        [[ -e $dir/CACHEDIR.TAG || -e $dir/debug/.cargo-lock \
          || -e $dir/release/.cargo-lock ]] || continue
        ;;
      node_modules) [[ -e ${dir%/*}/package.json ]] || continue ;;
      build | .dart_tool) [[ -e ${dir%/*}/pubspec.yaml ]] || continue ;;
    esac

    # Monorepo installs may only touch the root node_modules, so judge nested
    # ones by their outermost ancestor node_modules
    ref=$dir
    if [[ $name == node_modules ]]; then
      parent=${dir%/*}
      while parent=${parent%/*} && [[ $parent == "$HOME"/?* ]]; do
        [[ ! -d $parent/node_modules ]] || ref=$parent/node_modules
      done
    fi

    [[ -z $(find "$ref" -maxdepth 2 -mtime "-$days" -print -quit \
      2>/dev/null) ]] || continue
    remove "$dir"
  done < <(
    # Skip ~/Library (Xcode output is handled by `ios`), hidden ~/.* dirs,
    # which hold app state (e.g. editor extensions' node_modules, which sit
    # next to a package.json like build output does), and the read-only Go
    # module cache
    gomodcache=$(go env GOMODCACHE 2>/dev/null || true)
    find "$HOME" \
      \( -path "$HOME/Library" -o -path "$HOME/.*" -o -path "$gomodcache" \
        -o -name .git -o -name .jj \) -prune \
      -o -type d \( -name target -o -name node_modules -o -name build \
        -o -name .dart_tool \) -prune -print0 2>/dev/null
  )
}

clean_caches() {
  echo "==> Package-manager caches"
  # Idle Gradle daemons break if their caches vanish
  pkill -f GradleDaemon || true
  remove \
    "$HOME/.npm/_cacache" \
    "$HOME/.npm/_npx" \
    "$HOME/.pub-cache/git" \
    "$HOME/.pub-cache/hosted" \
    "$HOME/.pub-cache/hosted-hashes" \
    "$HOME/.gradle/caches" \
    "$HOME/.gradle/wrapper/dists"
  # The module cache is read-only, so let go handle it
  ! command -v go &>/dev/null || go clean -modcache

  [[ $(uname -s) == Darwin ]] || return 0
  echo "==> App caches"
  local caches="$HOME/Library/Caches"
  remove \
    "$caches/BraveSoftware" \
    "$caches/com.brave.Browser" \
    "$caches/zen" \
    "$caches/Mozilla" \
    "$caches/go-build" \
    "$caches/uv" \
    "$caches/Homebrew" \
    "$caches/electron"
}

# Uninstall non-default toolchains with no binary run (per atime) within
# `days`; rustup reinstalls any pinned by rust-toolchain.toml on demand
clean_rust() {
  local days="${1:-7}"
  command -v rustup &>/dev/null || return 0
  echo "==> Rust toolchains (unused for $days days)"
  local default dir toolchain
  default=$(rustup default | cut -d' ' -f1)
  for dir in "${RUSTUP_HOME:-$HOME/.rustup}"/toolchains/*; do
    toolchain=${dir##*/}
    [[ -d $dir/bin && $toolchain != "$default" ]] || continue
    [[ -z $(find "$dir/bin" -type f -atime "-$days" -print -quit) ]] || continue
    rustup toolchain uninstall "$toolchain"
  done
}

clean_ios() {
  local days="${1:-30}"
  xcrun --find simctl &>/dev/null || return 0
  echo "==> Xcode and iOS simulators (DeviceSupport older than $days days)"

  # Delete all but the newest simulator runtime per platform, along with its
  # dyld shared cache
  xcrun simctl runtime list -j | jq -r '
    [.[]] | group_by(.platformIdentifier)[]
    | sort_by([(.version | split(".") | map(tonumber)), .build])
    | .[:-1][] | "\(.identifier) \(.runtimeIdentifier) \(.version)"
  ' | while read -r id runtime version; do
    echo "delete runtime $runtime ($version)"
    xcrun simctl runtime dyld_shared_cache remove "$runtime"
    xcrun simctl runtime delete "$id"
  done
  xcrun simctl delete unavailable

  local xcode="$HOME/Library/Developer/Xcode"
  remove "$xcode/DerivedData"
  while IFS= read -r -d '' dir; do
    remove "$dir"
  done < <(
    find "$xcode/iOS DeviceSupport" -mindepth 1 -maxdepth 1 \
      -mtime "+$days" -print0 2>/dev/null
  )
}

avail_before=$(df -k "$HOME" | awk 'NR == 2 { print $4 }')

case "$section" in
  nix) clean_nix "$days" ;;
  build) clean_build "$days" ;;
  caches) clean_caches ;;
  rust) clean_rust "$days" ;;
  ios) clean_ios "$days" ;;
  *)
    echo >&2 "error: unknown section '$section'"
    exit 1
    ;;
esac

avail_after=$(df -k "$HOME" | awk 'NR == 2 { print $4 }')
echo "==> Freed $(((avail_after - avail_before) / 1048576)) GB"
