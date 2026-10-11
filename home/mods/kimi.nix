# Kimi K3 with confidential inference, pay-per-token.
#
# Primary route: Tinfoil (tinfoil.sh), which serves Kimi K3 inside a
# hardware enclave (AMD SEV-SNP + NVIDIA confidential compute). The
# `tinfoil-proxy` service below listens on 127.0.0.1:3301, verifies the
# enclave's attestation against Tinfoil's transparency log, and encrypts
# every request body to the enclave, so nothing between this machine and
# the enclave can read a prompt. Clients just see an OpenAI-compatible
# base URL. 256K context, pay-as-you-go, no subscription.
#
# No non-confidential fallback is wired on purpose. (TrustedRouter was
# tried: only a `provider` object in the request body pins it to a
# confidential host, which no CLI can send.)
#
# The key lives in ~/env/sensitive.sh as TINFOIL_API_KEY, per machine and
# never in this repo. On activation, kimi-sync.sh wires it into two tools
# whose mutable config files home-manager can't replace wholesale:
#
#  1. kimi CLI   ~/.kimi-code/config.toml  Providers + model aliases;
#                `tinfoil/kimi-k3` becomes the default model. Keyed by
#                `api_key_env`, so no secret is written.
#  2. Paseo      ~/.paseo/config.json      The key in the env of the ACP
#                `kimi` provider and the built-in `opencode` provider.
#                Paseo can't expand env vars in provider config, so the
#                key is literal.
#
# OpenCode needs no sync: its config reads the key from the environment,
# so home-manager owns ~/.config/opencode/opencode.json outright, with a
# `tinfoil` provider (`opencode -m tinfoil/kimi-k3`). Paseo runs the same
# binary and merges this global config, so it sees the provider too.
# (Codex is out: it sends `developer`-role messages, which Tinfoil's
# Responses API rejects.)
#
# Hosts without the key are left untouched.
{
  config,
  lib,
  pkgs,
  opencode,
  paseo,
  tinfoil-proxy,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # With no enclave pinned, the proxy discovers Tinfoil's model router
  # enclave and verifies it against the transparency log on startup.
  proxyArgs = [ "${tinfoil-proxy}/bin/tinfoil-proxy" ];

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    provider.tinfoil = {
      npm = "@ai-sdk/openai-compatible";
      name = "Tinfoil";
      options = {
        baseURL = "http://127.0.0.1:3301/v1";
        apiKey = "{env:TINFOIL_API_KEY}";
      };
      models.kimi-k3 = {
        name = "Kimi K3 (confidential)";
        limit = {
          context = 262144;
          output = 65536;
        };
      };
    };
  };

  sync = pkgs.writeShellApplication {
    name = "kimi-sync";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnused
      jq
    ];
    text = builtins.readFile ./kimi-sync.sh;
  };
in
{
  home.packages = [ opencode tinfoil-proxy ];

  xdg.configFile."opencode/opencode.json".text =
    builtins.toJSON opencodeConfig;

  # Linux — systemd user service
  systemd.user.services.tinfoil-proxy = lib.mkIf isLinux {
    Install.WantedBy = [ "default.target" ];

    Unit = {
      Description = "Tinfoil Proxy";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = lib.escapeShellArgs proxyArgs;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # macOS — launchd agent
  launchd.agents.tinfoil-proxy = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProcessType = "Background";
      ProgramArguments = proxyArgs;
      WorkingDirectory = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ThrottleInterval = 5;
    };
  };

  home.activation.kimiSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PASEO_BIN=${paseo}/bin/paseo ${sync}/bin/kimi-sync
    '';
}
