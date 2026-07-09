# Global justfile — machine-wide recipes, run from anywhere with `just -g <recipe>`.
# Home-manager deploys this and the just/ tree to ~/.config/just/ (see
# home/mods/core.nix).

mod workspace 'just/workspace/mod.just'
mod worktree 'just/worktree/mod.just'
