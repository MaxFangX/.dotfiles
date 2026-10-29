# A browser for agents, driven over the Chrome DevTools Protocol (CDP)
# through Vercel's `agent-browser`, as an MCP server or a CLI. See the
# agent-browser skill. Two modes, picked per machine:
#
# Headed (default): one Brave instance, started with `agent-brave` and
# left open, listens on a local CDP port. Unlike macctl it keeps
# working with the screen locked. Chromium refuses remote debugging on
# its default data dir, so it gets its own, which also keeps the main
# profile out. Every agent shares its cookies, so the human can sign in
# once for all of them.
#
# Headless: for hosts without a display. There is no launcher or CDP
# port. Instead, each agent launches its own private headless Chromium,
# the build nixpkgs ships for Playwright, which is patched to run on
# NixOS.
{ config, lib, pkgs, agent-browser, ... }:
let
  cfg = config.agent-browser;
  port = 9222;
  inherit (pkgs.stdenv) isDarwin;
  dataDir =
    if isDarwin then
      "${config.home.homeDirectory}"
      + "/Library/Application Support/BraveSoftware/Agent-Browser"
    else
      "${config.xdg.configHome}/BraveSoftware/Agent-Browser";
  brave =
    if isDarwin then
      "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    else
      "${pkgs.brave}/bin/brave";
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
  chromium =
    "${pkgs.playwright-driver.components.chromium}/chrome-linux/chrome";
  ab = lib.getExe agent-browser;
  # Claude Code starts one MCP server per session; give each its own
  # agent-browser session, and thus tab. CDP-attached sessions never idle
  # out, so stop the daemon once the server exits. All tools, since Claude
  # Code loads schemas on demand and smaller profiles lack hover and drag.
  mcpServer = pkgs.writeShellScript "agent-browser-mcp" ''
    ${lib.optionalString cfg.headless
      "export AGENT_BROWSER_EXECUTABLE_PATH=${chromium}"}
    export AGENT_BROWSER_SESSION="mcp-$(date +%s)-$$"
    # Background jobs read /dev/null unless stdin is passed explicitly.
    ${ab} mcp --tools all <&0 &
    server=$!
    trap 'kill "$server" 2>/dev/null' TERM INT HUP
    # A trapped signal interrupts `wait`, so wait again for the server.
    wait "$server"; wait "$server"
    ${ab} close >/dev/null 2>&1
  '';
in
{
  imports = [ ./claude-mcp.nix ];

  options.agent-browser.headless = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description =
      "Give each agent a private headless Chromium instead of sharing "
      + "one headed Brave over CDP.";
  };

  config = {
    home.packages = [ agent-browser ]
      ++ lib.optional (!cfg.headless) launcher;

    home.file = {
      ".claude/skills/agent-browser".source = ../../ai/skills/agent-browser;
      ".codex/skills/agent-browser".source = ../../ai/skills/agent-browser;
    } // lib.optionalAttrs (!cfg.headless) {
      # CLI defaults: attach to this browser, one pinned tab per session.
      ".agent-browser/config.json".text = builtins.toJSON {
        cdp = toString port;
        pinTab = true;
      };
    };

    # With no `cdp` configured, the CLI launches this browser itself.
    home.sessionVariables = lib.optionalAttrs cfg.headless {
      AGENT_BROWSER_EXECUTABLE_PATH = chromium;
    };

    claude-mcp.servers.agent-browser = {
      type = "stdio";
      command = "${mcpServer}";
    };
  };
}
