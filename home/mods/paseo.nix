# Paseo dev — provide `cross-env` on PATH for paseo.json scripts.
#
# Paseo's paseo.json setup/service commands (e.g. `Scripts > desktop`,
# worktree setup) invoke a bare `cross-env`, which normally resolves
# from the repo's node_modules/.bin. Our nix-managed PATH doesn't
# include that dir, so those commands die with `command not found:
# cross-env`.
#
# We're on a fork that continually rebases onto upstream Paseo, so we
# fix this in the environment rather than editing the upstream-tracked
# paseo.json (every command line there would conflict on rebase). The
# shim just delegates to the real cross-env shipped in the Paseo
# checkout, and is only installed when that checkout exists in ~/dev.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  paseoRepo = "${homeDir}/dev/paseo";

  crossEnv = pkgs.writeShellScriptBin "cross-env" ''
    # Delegate to the Paseo checkout's real cross-env. Prefer the repo
    # of the current working dir (e.g. a worktree under ~/.paseo) when
    # it has one, then fall back to the canonical checkout in ~/dev.
    for bin in \
      "$PWD/node_modules/.bin/cross-env" \
      "${paseoRepo}/node_modules/.bin/cross-env"; do
      if [ -x "$bin" ]; then
        exec "$bin" "$@"
      fi
    done
    echo "cross-env shim: no cross-env found in $PWD or ${paseoRepo}" >&2
    exit 127
  '';
in
{
  # Only put the shim on PATH when a Paseo checkout is present.
  home.packages = lib.optional (builtins.pathExists paseoRepo) crossEnv;
}
