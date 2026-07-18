# Shared by add.sh/remove.sh: resolve the <dir> argument. Absolute paths and
# relative paths landing outside the current repo pass through unchanged. A
# relative path that lands *inside* the repo (e.g. `add max/07-18-foo` from
# within the checkout) almost certainly wasn't meant literally, so reinterpret
# it as a path under the repo's workspaces dir: the nearest `workspaces` next
# to an ancestor of the repo root (e.g. ~/lexe/workspaces for the repo
# ~/lexe/org/lexe), created adjacent to the repo root if none exists yet.
resolve_workspace_dir() {
    local dir="$1"
    if [[ "$dir" == /* ]]; then
        echo "$dir"
        return
    fi

    # Lexical resolution only (-m): `add`'s path doesn't exist yet.
    local abs root
    abs="$(realpath -m "$PWD/$dir")"
    root="$(jj root 2>/dev/null || true)"
    if [[ -z "$root" || "$abs" != "$root/"* ]]; then
        echo "$dir"
        return
    fi

    # Find the workspaces dir, searching no higher than $HOME.
    local anc ws=""
    anc="$(dirname "$root")"
    while :; do
        if [[ -d "$anc/workspaces" ]]; then
            ws="$anc/workspaces"
            break
        fi
        [[ "$anc" == "$HOME" || "$anc" == "/" ]] && break
        anc="$(dirname "$anc")"
    done
    if [[ -z "$ws" ]]; then
        ws="$(dirname "$root")/workspaces"
        mkdir -p "$ws"
    fi

    echo "Interpreting '$dir' as $ws/$dir" >&2
    echo "$ws/$dir"
}
