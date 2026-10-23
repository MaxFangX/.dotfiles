# Maple: confidential inference, pay-per-token, Pro subscription.
#
# Maple (maple.ai, by OpenSecret) fronts open-weight models with an AWS
# Nitro enclave; its DeepSeek models run on Tinfoil-hosted GPU enclaves
# behind it, per Maple's published container configs. Its API needs an
# attestation handshake no CLI can do, so the `maple-proxy` service
# below listens on 127.0.0.1:3302, verifies the Nitro enclave against
# Maple's PCR0 trust roots, and encrypts every request to it, exposing a
# plain OpenAI-compatible base URL. Only that first enclave is attested
# locally. Clients authenticate per request with MAPLE_API_KEY, so the
# proxy holds no secret.
#
# Maple is twice Tinfoil's price for the same DeepSeek build, so it is
# the route for models Tinfoil does not carry. Its DeepSeek entries
# (`curl 127.0.0.1:3302/v1/models`) have a 1M context, tool use, vision,
# and reasoning efforts low/high/xhigh/max, default high.
#
# Client wiring lives in confidential.nix.
{
  config,
  lib,
  pkgs,
  maple-proxy,
  ...
}:
let
  mkService = import ./user-service.nix { inherit config lib pkgs; };

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
      exec maple-proxy --port 3302
    '';
  };

  proxy = mkService "Maple Proxy" (lib.getExe proxyStart);
in
{
  home.packages = [ maple-proxy ];

  systemd.user.services.maple-proxy = proxy.systemd;
  launchd.agents.maple-proxy = proxy.launchd;
}
