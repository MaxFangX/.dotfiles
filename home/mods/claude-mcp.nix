# MCP servers for Claude Code, declared in nix.
#
# Claude Code keeps user-scope MCP servers in ~/.claude.json, a file it
# rewrites constantly, so home-manager can't own it (see the
# settings.json note in core.nix). On activation, claude-mcp-sync.sh
# merges one `mcpServers.<name>` entry per server into ~/.claude.json and
# leaves the rest of the file alone.
#
# OAuth servers are authenticated once via `/mcp` in Claude Code. Static
# credentials stay out of this repo, so an entry references one as `$VAR`
# and the sync script fills it in from the per-machine ~/env/sensitive.sh,
# skipping the server if it's unset.
{ config, lib, pkgs, ... }:
let
  cfg = config.claude-mcp;
  servers = pkgs.writeText "claude-mcp-servers.json"
    (builtins.toJSON cfg.servers);
  sync = pkgs.writeShellApplication {
    name = "claude-mcp-sync";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = builtins.readFile ./claude-mcp-sync.sh;
  };
in
{
  options.claude-mcp.servers = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = {};
    description =
      "MCP server entries merged into ~/.claude.json, with `$VAR` "
      + "credential references filled in from ~/env/sensitive.sh.";
  };

  config.home.activation.claudeMcpSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_MCP_SERVERS=${servers} ${sync}/bin/claude-mcp-sync
    '';
}
