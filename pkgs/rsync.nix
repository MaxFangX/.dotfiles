# Platform-aware rsync wrapper.
#
# On macOS, xcodebuild calls rsync with Apple-specific flags like
# --extended-attributes that nixpkgs rsync doesn't support. This wrapper
# detects those flags and falls back to /usr/bin/rsync.
#
# See also: home/mods/dev-lexe/ios.nix
{ pkgs }:
if pkgs.stdenv.isDarwin then
  pkgs.writeShellScriptBin "rsync" ''
    for arg in "$@"; do
      [[ "$arg" == "--extended-attributes" ]] && exec /usr/bin/rsync "$@"
    done
    exec ${pkgs.rsync}/bin/rsync "$@"
  ''
else
  pkgs.rsync
