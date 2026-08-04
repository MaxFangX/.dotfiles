# Codex ACP adapter (@agentclientprotocol/codex-acp).
#
# Bridges the Codex CLI to Agent Client Protocol clients like goose or
# Zed, which spawn `codex-acp` and speak ACP JSON-RPC over stdio.
# CODEX_PATH points at our nix-packaged codex (see pkgs/codex) so the
# adapter uses the same pinned, sandbox-wrapped binary instead of the
# npm-bundled one; export CODEX_PATH to override.
#
# Built from a committed lockfile like pkgs/paseo: package.json pins the
# version, and importNpmLock fetches each dependency using the
# integrity hashes recorded in package-lock.json — no separate Nix
# hash. Update with `just update codex-acp`.
{
  lib,
  stdenvNoCC,
  nodejs,
  makeWrapper,
  importNpmLock,
  codex,
}:
let
  nodeModules = importNpmLock.buildNodeModules {
    npmRoot = ./.;
    inherit nodejs;
  };
  entry = "${nodeModules}/node_modules"
    + "/@agentclientprotocol/codex-acp/dist/index.js";
in
stdenvNoCC.mkDerivation {
  pname = "codex-acp";
  version =
    (lib.importJSON ./package-lock.json)
    .packages."node_modules/@agentclientprotocol/codex-acp".version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    makeWrapper ${nodejs}/bin/node $out/bin/codex-acp \
      --add-flags ${entry} \
      --set-default CODEX_PATH ${lib.getExe codex}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "ACP adapter for the Codex CLI";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    mainProgram = "codex-acp";
    # Limited by the wrapped codex binary.
    inherit (codex.meta) platforms;
  };
}
