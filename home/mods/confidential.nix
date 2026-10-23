# Confidential inference for Claude Code: DeepSeek V4.1 Flash via Maple,
# pay-per-token, reached through a local attestation-verifying proxy
# (maple.nix). Tinfoil (tinfoil.nix) is the second such proxy.
#
# Keys live in ~/env/sensitive.sh as TINFOIL_API_KEY and MAPLE_API_KEY,
# per machine and never in this repo. Paseo can't expand env vars in
# provider config, so confidential-sync.sh writes a `claude-deepseek`
# provider into ~/.paseo/config.json on activation, extending `claude`
# with the router env from maple.nix and the literal key. Hosts without
# the key skip it.
#
# Codex is out. It sends `developer`-role messages, which Tinfoil's
# Responses API rejects, and Maple has no Responses API at all.
{
  lib,
  pkgs,
  paseo,
  ...
}:
let
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

  home.activation.confidentialSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PASEO_BIN=${paseo}/bin/paseo ${sync}/bin/confidential-sync
    '';
}
