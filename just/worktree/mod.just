# Git worktree management, run from anywhere with `just -g worktree <recipe>`.
# Each recipe acts on the repo in your current directory (`[no-cd]`); the logic
# lives in the sibling scripts, located via `source_directory()`.

set shell := ["bash", "-euo", "pipefail", "-c"]

# Create a git worktree for AI development. Best run from the main worktree.
[no-cd]
add dir:
    @{{ source_directory() }}/add.sh {{ quote(dir) }}

# Remove a git worktree and its associated branch.
[no-cd]
remove dir *args:
    @{{ source_directory() }}/remove.sh {{ quote(dir) }} {{ args }}

# Make a worktree the primary (main) worktree, carrying colocated jj along. Defaults to cwd.
[no-cd]
set-primary dir=".":
    @{{ source_directory() }}/set-primary.sh {{ quote(dir) }}
