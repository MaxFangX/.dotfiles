# Claude Code ACP adapter (@zed-industries/claude-agent-acp).
#
# Bridges Claude Code (via the Claude Agent SDK) to Agent Client
# Protocol clients like goose or Zed, which spawn `claude-agent-acp`
# and speak ACP JSON-RPC over stdio.
#
# Built from a committed lockfile like pkgs/paseo: package.json pins the
# version, and importNpmLock fetches each dependency using the
# integrity hashes recorded in package-lock.json — no separate Nix
# hash. Update with `just update claude-agent-acp`.
{
  lib,
  stdenvNoCC,
  nodejs,
  makeWrapper,
  importNpmLock,
}:
let
  nodeModules = importNpmLock.buildNodeModules {
    npmRoot = ./.;
    inherit nodejs;
  };
  entry = "${nodeModules}/node_modules"
    + "/@zed-industries/claude-agent-acp/dist/index.js";
in
stdenvNoCC.mkDerivation {
  pname = "claude-agent-acp";
  version =
    (lib.importJSON ./package-lock.json)
    .packages."node_modules/@zed-industries/claude-agent-acp".version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    makeWrapper ${nodejs}/bin/node $out/bin/claude-agent-acp \
      --add-flags ${entry}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "ACP adapter for Claude Code";
    homepage = "https://github.com/zed-industries/claude-agent-acp";
    mainProgram = "claude-agent-acp";
    platforms = lib.platforms.unix;
  };
}
