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
#
# A server's tool names and instructions sit in every session's context,
# so servers used only from a skill are declared on-demand. They stay in
# ~/.claude.json, where `mcp-cli` finds them and their OAuth credentials,
# but Claude Code can only disable a user-scope server per project. So
# the sync disables them in every project ~/.claude.json lists, and a
# project first seen after the last activation loads them until the next.
{ config, lib, pkgs, mcp-cli, ... }:
let
  cfg = config.claude-mcp;
  servers = pkgs.writeText "claude-mcp-servers.json"
    (builtins.toJSON cfg.servers);
  onDemand = builtins.toJSON cfg.onDemandServers;
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

  options.claude-mcp.onDemandServers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = [ "folk" ];
    description =
      "The subset of `claude-mcp.servers` that sessions never load. "
      + "Reachable through `mcp-cli <server> <tool>` from a skill.";
  };

  options.claude-mcp.confidentialServers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = [ "agent-browser" ];
    description =
      "The subset of `claude-mcp.servers` that `claude-confidential` "
      + "gets (see confidential.nix).";
  };

  config.home.packages = [ mcp-cli ];

  config.home.activation.claudeMcpSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_MCP_SERVERS=${servers} \
        CLAUDE_MCP_ON_DEMAND=${lib.escapeShellArg onDemand} \
        ${sync}/bin/claude-mcp-sync
    '';
}
