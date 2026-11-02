# mcp-cli: call one tool on one MCP server from the shell. It resolves
# the server in Claude Code's own configuration (~/.claude.json and
# project .mcp.json) and shares Claude Code's OAuth credentials, so a
# server that sessions don't load (see claude-mcp.onDemandServers in
# home/mods/claude-mcp.nix) is still callable from a skill.
#
# Upstream has tags but no releases; pinned to a commit. Update with
# `just update mcp-cli`.
{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
let
  source = lib.importJSON ./source.json;
in
buildGoModule {
  pname = "mcp-cli";
  version = "0.6.0-unstable-${source.date}";
  inherit (source) vendorHash;

  src = fetchFromGitHub {
    owner = "tkukushkin";
    repo = "mcp-cli";
    inherit (source) rev hash;
  };

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Call MCP tools configured for Claude Code from the shell";
    homepage = "https://github.com/tkukushkin/mcp-cli";
    license = lib.licenses.mit;
    mainProgram = "mcp-cli";
  };
}
