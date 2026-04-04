# Declarative Homebrew cask management for macOS.
# Modules add casks via `homebrew.casks = [ "foo" ];` and lists merge.
# On activation, generates a Brewfile and runs `brew bundle --cleanup`.
{ config, lib, pkgs, ... }:
{
  options.homebrew.casks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Homebrew casks to install";
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && config.homebrew.casks != []) {
    home.activation.brewBundle =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        BREWFILE=$(mktemp)
        printf '%s\n' \
          ${lib.escapeShellArgs
            (map (c: ''cask "${c}"'') config.homebrew.casks)} \
          > "$BREWFILE"
        /opt/homebrew/bin/brew bundle \
          --file="$BREWFILE" --cleanup --force
        rm "$BREWFILE"
      '';
  };
}
