# Confidential inference for the agent CLIs: Kimi K3 via Tinfoil and
# DeepSeek V4.1 Flash via Maple, both pay-per-token, both reached through
# a local attestation-verifying proxy (tinfoil.nix, maple.nix). This
# module wires those proxies into the clients.
#
# Keys live in ~/env/sensitive.sh as TINFOIL_API_KEY and MAPLE_API_KEY,
# per machine and never in this repo. The OpenCode provider reads the env
# at call time, so hosts without a key still get it, but the sync below
# skips that provider's kimi and Paseo entries.
#
#  1. OpenCode   ~/.config/opencode/opencode.json  Owned outright by
#                home-manager, with one provider per proxy keyed by
#                `{env:…_API_KEY}` (`opencode -m maple/deepseek-v4-1-flash`).
#                Paseo runs the same binary and merges this global config.
#
#  2. kimi CLI   ~/.kimi-code/config.toml  Mutable, so confidential-sync.sh
#                splices one marker-delimited block of providers + model
#                aliases on activation. `tinfoil/kimi-k3` is the default.
#                Keyed by `api_key_env`, so no secret is written.
#
#  3. Paseo      ~/.paseo/config.json  The keys go in the env of the ACP
#                `kimi` provider and the built-in `opencode` provider,
#                and a `claude-deepseek` provider extends `claude` with
#                the router env from maple.nix. Paseo can't expand env
#                vars in provider config, so the keys are literal.
#
# Codex is out. It sends `developer`-role messages, which Tinfoil's
# Responses API rejects, and Maple has no Responses API at all.
{
  lib,
  pkgs,
  opencode,
  paseo,
  ...
}:
let
  deepseekModel = name: {
    inherit name;
    reasoning = true;
    tool_call = true;
    attachment = true;
    # Maple streams thinking in `delta.reasoning`.
    interleaved.field = "reasoning";
    limit = {
      context = 1048576;
      output = 131072;
    };
    # `--variant <effort>` picks the reasoning effort; Maple defaults to
    # high.
    variants = lib.genAttrs [ "low" "high" "xhigh" "max" ] (
      effort: { reasoningEffort = effort; }
    );
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      tinfoil = {
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
      maple = {
        npm = "@ai-sdk/openai-compatible";
        name = "Maple";
        options = {
          baseURL = "http://127.0.0.1:3302/v1";
          apiKey = "{env:MAPLE_API_KEY}";
        };
        models = {
          deepseek-v4-1-flash =
            deepseekModel "DeepSeek V4.1 Flash (confidential)";
          deepseek-v4-1-flash-1017-uncensored =
            deepseekModel "DeepSeek V4.1 Flash Uncensored (confidential)";
        };
      };
    };
  };

  sync = pkgs.writeShellApplication {
    name = "confidential-sync";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnused
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

  home.packages = [ opencode ];

  xdg.configFile."opencode/opencode.json".text =
    builtins.toJSON opencodeConfig;

  home.activation.confidentialSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PASEO_BIN=${paseo}/bin/paseo ${sync}/bin/confidential-sync
    '';
}
