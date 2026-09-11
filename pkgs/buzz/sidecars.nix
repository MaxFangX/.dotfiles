{
  cacert,
  gitMinimal,
  lib,
  rustPlatform,

  src,
  version,
}:

let
  # One crate per bundled sidecar; the binary names live in
  # default.nix's sidecarNames (buzz-cli's binary is `buzz`).
  sidecarCrates = [
    "buzz-acp"
    "buzz-agent"
    "buzz-backend-kubernetes"
    "buzz-dev-mcp"
    "git-credential-nostr"
    "buzz-cli"
  ];
  sidecarPackageFlags = lib.concatMap (crate: [
    "-p"
    crate
  ]) sidecarCrates;
in

rustPlatform.buildRustPackage {
  pname = "buzz-sidecars";
  inherit src version;

  cargoHash = "sha256-D9w9DA6i+W9xOy9b/1/dNc50XkJCKyNNdV1sHpLXZvE=";
  cargoBuildFlags = sidecarPackageFlags;
  cargoTestFlags = sidecarPackageFlags;

  # Tests construct HTTPS clients and invoke Git inside the Nix sandbox.
  nativeCheckInputs = [
    cacert
    gitMinimal
  ];

  # buzz-dev-mcp's path tests write under $HOME.
  preCheck = ''
    export HOME="$NIX_BUILD_TOP/test-home"
    mkdir -p "$HOME"
  '';

  # These tests race wall-clock deadlines or response streams and flake under
  # the sandbox's parallel load (they pass in a normal checkout). The steer
  # family shares the response-stream race, so skip it wholesale.
  checkFlags = [
    "--skip=steer_"
    "--skip=keepalive_resets_idle_past_deadline"
    # Asserts a steer is accepted mid-turn (same race as the steer family).
    "--skip=handoff_cap_binds_within_a_single_turn"
    # 2s MCP init deadline; times out under sandbox load.
    "--skip=cancel_kills_inflight_tool_via_mcp_notification"
  ];

  postInstall = ''
    rm -f "$out/bin/fake-mcp"
  '';
}
