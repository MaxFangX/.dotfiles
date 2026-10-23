# Maple: DeepSeek V4.1 Flash with confidential inference, pay-per-token.
#
# Maple (maple.ai, by OpenSecret) serves open-weight models inside AWS
# Nitro enclaves on confidential-compute GPUs. Its API needs an
# attestation handshake no CLI can do, so two local services front it:
#
#  1. maple-proxy on 127.0.0.1:3302. Verifies the enclave against
#     Maple's PCR0 trust roots and encrypts every request to it, exposing
#     a plain OpenAI-compatible base URL. Clients authenticate per request
#     with MAPLE_API_KEY, so the proxy holds no secret.
#
#  2. claude-code-router on 127.0.0.1:3456. Maple only speaks Chat
#     Completions, so the router translates Claude Code's Anthropic
#     Messages API into it. `$MAPLE_API_KEY` is expanded from the env at
#     start, both as the upstream key and as the key clients must
#     present, so `claude` authenticates with the same Maple key:
#
#       ANTHROPIC_BASE_URL=http://127.0.0.1:3456 \
#       ANTHROPIC_AUTH_TOKEN=$MAPLE_API_KEY claude
#
#     The `openrouter` transformer closes Maple's thinking blocks early,
#     so no transformer is configured. Requests go to the default route
#     unless the model is named in the router's `provider,model` form,
#     e.g. for the uncensored variant:
#
#       ANTHROPIC_MODEL=maple,deepseek-v4-1-flash-1017-uncensored
#
#     Claude Code warns `unrecognized_model` and assumes a 200K context
#     for such names, so it compacts earlier than the 1M window needs.
#
# Both DeepSeek entries (`curl 127.0.0.1:3302/v1/models`) have a 1M
# context, tool use, vision, and reasoning efforts low/high/xhigh/max,
# default high.
#
# Client wiring (opencode, kimi, Paseo, aliases) lives in
# confidential.nix.
{
  config,
  lib,
  pkgs,
  claude-code-router,
  maple-proxy,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  homeDir = config.home.homeDirectory;
  envFile = "${homeDir}/env/sensitive.sh";

  proxyPort = 3302;
  routerPort = 3456;

  proxyStart = pkgs.writeShellApplication {
    name = "maple-proxy-start";
    runtimeInputs = [ pkgs.coreutils maple-proxy ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/maple-proxy"
      root="$state/cache-namespace-root"
      # Persisted so Maple's prompt cache survives proxy restarts.
      # Exactly 32 random bytes, padded base64.
      if [ ! -s "$root" ]; then
        mkdir -p "$state"
        (umask 077; head -c 32 /dev/urandom | base64 -w0 > "$root")
      fi
      MAPLE_CACHE_NAMESPACE_ROOT=$(cat "$root")
      export MAPLE_CACHE_NAMESPACE_ROOT
      exec maple-proxy --port ${toString proxyPort}
    '';
  };

  # Without a key the router would serve unauthenticated, so idle instead.
  routerStart = pkgs.writeShellApplication {
    name = "claude-code-router-start";
    runtimeInputs = [ claude-code-router ];
    text = ''
      # shellcheck disable=SC1091
      [ -f "${envFile}" ] && . "${envFile}"
      if [ -z "''${MAPLE_API_KEY:-}" ]; then
        echo "MAPLE_API_KEY not set in ${envFile}; not starting" >&2
        exit 0
      fi
      exec ccr start
    '';
  };

  routerConfig = {
    LOG = false;
    HOST = "127.0.0.1";
    PORT = routerPort;
    APIKEY = "$MAPLE_API_KEY";
    Providers = [
      {
        name = "maple";
        api_base_url =
          "http://127.0.0.1:${toString proxyPort}/v1/chat/completions";
        api_key = "$MAPLE_API_KEY";
        models = [
          "deepseek-v4-1-flash"
          "deepseek-v4-1-flash-1017-uncensored"
        ];
      }
    ];
    Router.default = "maple,deepseek-v4-1-flash";
  };

  mkService = description: start: {
    systemd = lib.mkIf isLinux {
      Install.WantedBy = [ "default.target" ];

      Unit = {
        Description = description;
        After = [ "network.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = lib.getExe start;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    launchd = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProcessType = "Background";
        ProgramArguments = [ (lib.getExe start) ];
        WorkingDirectory = homeDir;
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
        ThrottleInterval = 5;
      };
    };
  };

  proxy = mkService "Maple Proxy" proxyStart;
  router = mkService "Claude Code Router" routerStart;
in
{
  home.packages = [ claude-code-router maple-proxy ];

  # Nix-owned, so `ccr model` / `ccr ui` edits won't stick.
  home.file.".claude-code-router/config.json".text =
    builtins.toJSON routerConfig;

  systemd.user.services = {
    maple-proxy = proxy.systemd;
    claude-code-router = router.systemd;
  };

  launchd.agents = {
    maple-proxy = proxy.launchd;
    claude-code-router = router.launchd;
  };
}
