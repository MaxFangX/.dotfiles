# Per-host Claude Code settings, merged into ~/.claude/settings.json.
#
# Claude Code rewrites settings.json freely (`/effort` and friends), so
# home-manager can't own it (see the note in core.nix). Instead a host
# sets `claude.settings` and the keys are merged in on activation,
# leaving the rest of the file alone. A key removed here stays in the
# file until removed by hand.
{ config, lib, pkgs, ... }:
let
  cfg = config.claude.settings;
in
{
  options.claude.settings = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Keys merged into ~/.claude/settings.json on activation.";
    example = { cleanupPeriodDays = 1095; };
  };

  config.home.activation.claudeSettings = lib.mkIf (cfg != { }) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.claude/settings.json"
      mkdir -p "$HOME/.claude"
      [ -s "$cfg" ] || echo '{}' > "$cfg"
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq --indent 2 \
        --argjson s ${lib.escapeShellArg (builtins.toJSON cfg)} \
        '. * $s' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
    ''
  );
}
