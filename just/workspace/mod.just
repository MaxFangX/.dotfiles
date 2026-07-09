# Colocated jj workspace management, the jj analog of the `worktree` module,
# run from anywhere with `just -g workspace <recipe>`. A workspace is a git
# worktree with a colocated .jj, so all workspaces share one commit graph and
# op log. Each recipe acts on the repo in your current directory (`[no-cd]`);
# the logic lives in the sibling scripts, located via `source_directory()`.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Create a colocated jj workspace (+ git worktree). Best run from the repo.
[no-cd]
add dir:
    @{{ source_directory() }}/add.sh {{ quote(dir) }}

# Remove a jj workspace and its colocated git worktree, safely.
[no-cd]
remove dir *args:
    @{{ source_directory() }}/remove.sh {{ quote(dir) }} {{ args }}
