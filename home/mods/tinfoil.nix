# Tinfoil: confidential inference, pay-per-token.
#
# Tinfoil (tinfoil.sh) serves open-weight models inside hardware enclaves
# (AMD SEV-SNP + NVIDIA confidential compute). The `tinfoil-proxy` service
# below listens on 127.0.0.1:3301, verifies the enclave's attestation
# against Tinfoil's transparency log, and encrypts every request body to
# the enclave, so nothing between this machine and the enclave can read
# a prompt. Clients just see an OpenAI-compatible base URL and
# authenticate per request with TINFOIL_API_KEY. Pay-as-you-go, no
# subscription.
#
# No non-confidential fallback is wired on purpose. (TrustedRouter was
# tried: only a `provider` object in the request body pins it to a
# confidential host, which no CLI can send.)
#
# Client wiring lives in confidential.nix.
{
  config,
  lib,
  pkgs,
  tinfoil-proxy,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # With no enclave pinned, the proxy discovers Tinfoil's model router
  # enclave and verifies it against the transparency log on startup.
  proxyArgs = [ "${tinfoil-proxy}/bin/tinfoil-proxy" ];
in
{
  home.packages = [ tinfoil-proxy ];

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
}
