# Paseo CLI / daemon (@getpaseo/cli).
#
# Built from a committed lockfile. @getpaseo/cli ships no lockfile of its
# own, so we keep a package.json pinning the version and a generated
# package-lock.json alongside it. The lockfile records each dependency's
# `integrity` hash, and importNpmLock fetches each one using those
# hashes — so there is no separately-maintained Nix hash. The lock lists
# every platform's optional native deps (e.g. sherpa-onnx-*); only the
# ones matching the build host are fetched.
#
# Update with `just update paseo` (bumps the version and regenerates the
# lockfile). node is wrapped in because systemd/launchd start the daemon
# with no node on PATH.
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
in
stdenvNoCC.mkDerivation {
  pname = "paseo";
  version =
    (lib.importJSON ./package-lock.json)
    .packages."node_modules/@getpaseo/cli".version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    # Run the pinned node against the ESM entry; the dependency tree
    # sits alongside it in node_modules, so node resolves it.
    makeWrapper ${nodejs}/bin/node $out/bin/paseo \
      --add-flags "--disable-warning=DEP0040 ${nodeModules}/node_modules/@getpaseo/cli/dist/index.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Paseo CLI and daemon (@getpaseo/cli)";
    homepage = "https://paseo.sh";
    mainProgram = "paseo";
    platforms = lib.platforms.unix;
  };
}
