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
# clean.sh <section> [days] [keep]
#
# ## Args
#
# section = nix | build | caches | builder | rust | ios
# days    = Age threshold overriding the section default: entries untouched
#           for longer than this are deleted. Section defaults:
#             nix    30  Home Manager / profile generations
#             build   0  Cargo, npm, Flutter build output dirs
#             rust    7  rustup toolchains (per binary atime)
#             ios    30  Xcode iOS DeviceSupport entries
#           `caches` and `builder` take no threshold.
# keep    = `nix` only: the newest generations kept in each profile
#           regardless of age (default 3). On a machine that rebuilds many
#           times a day, 30 days holds hundreds of generations, so `days`
#           alone barely shrinks the store.

section="${1:?usage: clean.sh <section> [days] [keep]}"
days="${2:-}"
keep="${3:-}"

remove() {
  for path in "$@"; do
    [[ -e $path ]] || continue
    echo "rm $path"
    # Some build output (e.g. Flutter.framework in DerivedData) is read-only
    rm -rf "$path" 2>/dev/null || { chmod -R u+w "$path" && rm -rf "$path"; }
  done
}

clean_nix() {
  local days="${1:-30}" keep="${2:-3}" profile
  echo "==> Nix (generations older than $days days, keeping newest $keep)"
  home-manager expire-generations "-$days days"
  nix profile wipe-history --older-than "${days}d"
  # `+N` never deletes the current generation, even after a rollback
  for profile in "$HOME/.local/state/nix/profiles/home-manager" \
    "/nix/var/nix/profiles/per-user/$USER/profile"; do
    [[ -e $profile ]] || continue
    nix-env --profile "$profile" --delete-generations "+$keep"
  done
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
    # Prune trees whose matches must not be deleted here:
    # - Other filesystems, such as the VM disk mounted at ~/OrbStack, whose
    #   Nix store holds Flutter sources.
    # - ~/Library, as `ios` handles Xcode output.
    # - Hidden ~/.* dirs, which hold app state. For example, editor
    #   extensions keep node_modules next to a package.json.
    # - The Go module cache, which `caches` clears.
    gomodcache=$(go env GOMODCACHE 2>/dev/null || true)
    find "$HOME" -xdev \
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
    "$caches/electron" \
    "$caches/lexe-bot-targets"

  # Brave clones its bundle into the per-user temp dir at launch, and leaks
  # the clone whenever it doesn't exit cleanly. $TMPDIR may be overridden, as
  # Claude Code does, so find that dir with `getconf`.
  remove "$(getconf DARWIN_USER_TEMP_DIR)../X/com.brave.Browser.code_sign_clone"
  # rust-analyzer's check target dir (see nvim/coc-settings.json)
  remove /private/tmp/rust-analyzer-check
}

# GC the Nix store in OrbStack's linux-builder VM, which the host's
# `nix store gc` can't see
clean_builder() {
  command -v orb &>/dev/null || return 0
  orb list 2>/dev/null | awk '
    $1 == "linux-builder" && $2 == "running" { up = 1 }
    END { exit !up }
  ' || return 0
  echo "==> OrbStack linux-builder Nix store"
  orb -m linux-builder -u root nix store gc
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
  nix) clean_nix "$days" "$keep" ;;
  build) clean_build "$days" ;;
  caches) clean_caches ;;
  builder) clean_builder ;;
  rust) clean_rust "$days" ;;
  ios) clean_ios "$days" ;;
  *)
    echo >&2 "error: unknown section '$section'"
    exit 1
    ;;
esac

avail_after=$(df -k "$HOME" | awk 'NR == 2 { print $4 }')
echo "==> Freed $(((avail_after - avail_before) / 1048576)) GB"
