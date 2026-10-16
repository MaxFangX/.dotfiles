# A Brave instance agents drive over the Chrome DevTools Protocol (CDP),
# started with `agent-brave` and left open. Unlike macctl it keeps working
# with the screen locked. Chromium refuses remote debugging on its default
# data dir, so it gets its own, which also keeps the main profile out.
# Agents attach through the Playwright MCP server or Vercel's
# `agent-browser` CLI; see the agent-browser skill.
{ config, lib, pkgs, agent-browser, ... }:
let
  port = 9222;
  dataDir = "${config.home.homeDirectory}"
    + "/Library/Application Support/BraveSoftware/Agent-Browser";
  brave = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser";
  # Idempotent and detached: returns once the CDP port answers, whether
  # the browser was already up or this call launched it, so agents can
  # run it themselves and a human's terminal is not tied up.
  launcher = pkgs.writeShellScriptBin "agent-brave" ''
    alive() {
      ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString port}/json/version \
        >/dev/null
    }
    if ! alive; then
      nohup "${brave}" \
        --user-data-dir="${dataDir}" \
        --remote-debugging-port=${toString port} \
        --no-first-run --no-default-browser-check "$@" >/dev/null 2>&1 &
      for _ in $(seq 50); do alive && break; sleep 0.2; done
    fi
    alive || {
      echo "agent-brave: port ${toString port} not answering" >&2
      exit 1
    }
  '';
in
{
  imports = [ ./claude-mcp.nix ];

  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.packages = [ launcher agent-browser pkgs.playwright-mcp ];

    home.file = {
      # CLI defaults: attach to this browser, one pinned tab per session.
      ".agent-browser/config.json".text = builtins.toJSON {
        cdp = toString port;
        pinTab = true;
      };
      ".claude/skills/agent-browser".source = ../../ai/skills/agent-browser;
      ".codex/skills/agent-browser".source = ../../ai/skills/agent-browser;
    };

    claude-mcp.servers.agent-browser = {
      type = "stdio";
      command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
      args = [ "--cdp-endpoint" "http://127.0.0.1:${toString port}" ];
    };
  };
}
