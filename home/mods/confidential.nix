# Confidential inference for Claude Code: DeepSeek V4.1 Flash, served
# inside hardware enclaves by Tinfoil (tinfoil.nix) and Maple
# (maple.nix), each behind a local attestation-verifying proxy. Tinfoil
# is the default route at half of Maple's price; Maple also carries
# models Tinfoil does not. Both proxies speak only OpenAI Chat
# Completions, so three pieces sit between Claude Code and them:
#
#  1. claude-code-router on 127.0.0.1:3456 translates Claude Code's
#     Anthropic Messages API, with one upstream per proxy. Keys are
#     expanded from the env at start, and clients authenticate to the
#     router with the Tinfoil key. Requests go to the default route
#     unless the model is named in the router's `provider,model` form:
#
#       ANTHROPIC_MODEL=maple,deepseek-v4-1-flash
#
#     Claude Code warns `unrecognized_model` and assumes a 200K context
#     for such names, so it compacts earlier than the 1M window needs.
#     The `openrouter` transformer closes thinking blocks early, so no
#     transformer is configured.
#
#  2. `claude-confidential` wraps `claude` for that router. It sets the
#     base URL and token and turns off nonessential traffic (telemetry,
#     error reports, update checks), so the proxy is the session's only
#     outbound connection. Enclave tokens cost several times commodity
#     hosting and the global MCP set adds ~56K tokens of tool schemas to
#     every turn, so MCP is restricted to `mcpServers` below, picked out
#     of ~/.claude.json by name. `--strict-mcp-config` drops project
#     `.mcp.json` servers but keeps `--mcp-config` ones, so Paseo's own
#     MCP injection still applies.
#
#  3. Paseo can't expand env vars in provider config, so
#     confidential-sync.sh writes a `claude-confidential` provider that
#     extends `claude` with the wrapper as its command and the literal
#     key in its env, with one model entry per route.
#
# Keys live in ~/env/sensitive.sh as TINFOIL_API_KEY and MAPLE_API_KEY,
# per machine and never in this repo. Everything here needs the Tinfoil
# key and idles without it; the Maple routes additionally need theirs.
#
# Codex is out. It sends `developer`-role messages, which Tinfoil's
# Responses API rejects, and Maple has no Responses API at all.
{
  config,
  lib,
  pkgs,
  claude-code,
  claude-code-router,
  paseo,
  ...
}:
let
  mkService = import ./user-service.nix { inherit config lib pkgs; };

  envFile = "${config.home.homeDirectory}/env/sensitive.sh";
  routerPort = 3456;

  # MCP servers from ~/.claude.json that confidential sessions keep.
  mcpServers = [ "agent-browser" ];

  routerConfig = {
    LOG = false;
    HOST = "127.0.0.1";
    PORT = routerPort;
    APIKEY = "$TINFOIL_API_KEY";
    Providers = [
      {
        name = "tinfoil";
        api_base_url = "http://127.0.0.1:3301/v1/chat/completions";
        api_key = "$TINFOIL_API_KEY";
        models = [ "deepseek-v4-1-flash" ];
      }
      {
        name = "maple";
        api_base_url = "http://127.0.0.1:3302/v1/chat/completions";
        api_key = "$MAPLE_API_KEY";
        models = [
          "deepseek-v4-1-flash"
          "deepseek-v4-1-flash-1017-uncensored"
        ];
      }
    ];
    Router.default = "tinfoil,deepseek-v4-1-flash";
  };

  # Without the Tinfoil key the router would serve unauthenticated, so
  # idle instead.
  routerStart = pkgs.writeShellApplication {
    name = "claude-code-router-start";
    runtimeInputs = [ claude-code-router ];
    text = ''
      # shellcheck disable=SC1091
      [ -f "${envFile}" ] && . "${envFile}"
      if [ -z "''${TINFOIL_API_KEY:-}" ]; then
        echo "TINFOIL_API_KEY not set in ${envFile}; not starting" >&2
        exit 0
      fi
      export MAPLE_API_KEY="''${MAPLE_API_KEY:-}"
      # ccr idles if its pid file names a live process, even one from a
      # manual run, and the service is the only legitimate instance.
      rm -f "$HOME/.claude-code-router/.claude-code-router.pid"
      exec ccr start
    '';
  };

  router = mkService "Claude Code Router" (lib.getExe routerStart);

  wrapper = pkgs.writeShellApplication {
    name = "claude-confidential";
    runtimeInputs = [ claude-code pkgs.jq ];
    text = ''
      if [ -z "''${TINFOIL_API_KEY:-}" ]; then
        # shellcheck disable=SC1091
        [ -f "${envFile}" ] && . "${envFile}"
      fi
      : "''${TINFOIL_API_KEY:?not set in ${envFile}}"
      export ANTHROPIC_BASE_URL="http://127.0.0.1:${toString routerPort}"
      export ANTHROPIC_AUTH_TOKEN="$TINFOIL_API_KEY"
      export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

      mcp=$(jq -c --argjson keep '${builtins.toJSON mcpServers}' '
        { mcpServers: ((.mcpServers // {})
            | with_entries(select(.key as $k | $keep | index($k)))) }
      ' "$HOME/.claude.json" 2>/dev/null || echo '{"mcpServers":{}}')
      # `--mcp-config` is variadic, so it goes after the caller's arguments.
      exec claude "$@" --strict-mcp-config --mcp-config "$mcp"
    '';
  };

  sync = pkgs.writeShellApplication {
    name = "confidential-sync";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = builtins.readFile ./confidential-sync.sh;
  };
in
{
  imports = [
    ./maple.nix
    ./tinfoil.nix
  ];

  home.packages = [ claude-code-router wrapper ];

  # Nix-owned, so `ccr model` / `ccr ui` edits won't stick.
  home.file.".claude-code-router/config.json".text =
    builtins.toJSON routerConfig;

  systemd.user.services.claude-code-router = router.systemd;
  launchd.agents.claude-code-router = router.launchd;

  # Paseo resolves a provider's command without the daemon's PATH, so it
  # gets the wrapper's profile path, which exists once packages are
  # installed.
  home.activation.confidentialSync =
    lib.hm.dag.entryAfter [ "installPackages" ] ''
      PASEO_BIN=${paseo}/bin/paseo \
        WRAPPER=${config.home.profileDirectory}/bin/${wrapper.name} \
        ${sync}/bin/confidential-sync
    '';
}
