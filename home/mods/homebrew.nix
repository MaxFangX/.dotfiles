# Declarative Homebrew management for macOS.
# Modules add packages via `homebrew.{taps,brews,casks}` and lists merge.
# On activation, generates a Brewfile and runs `brew bundle --cleanup`.
{ config, lib, pkgs, ... }:
let
  cfg = config.homebrew;
  hasAny = cfg.taps != [] || cfg.brews != [] || cfg.casks != [];
in
{
  options.homebrew = {
    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Homebrew taps to add";
    };
    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Homebrew formulae to install";
    };
    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Homebrew casks to install";
    };
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && hasAny) {
    home.activation.brewBundle =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        BREWFILE=$(mktemp)
        printf '%s\n' \
          ${lib.escapeShellArgs (
            (map (t: ''tap "${t}"'') cfg.taps) ++
            (map (b: ''brew "${b}"'') cfg.brews) ++
            (map (c: ''cask "${c}"'') cfg.casks)
          )} \
          > "$BREWFILE"
        /opt/homebrew/bin/brew bundle \
          --file="$BREWFILE" --cleanup --force
        rm "$BREWFILE"
      '';
  };
}
