# Paseo CLI / daemon (@getpaseo/cli).
#
# Update with `./pkgs/paseo/update.sh`.
#
# Paseo is a pure-Node ESM app published to npm with no lockfile in its
# registry tarball, so buildNpmPackage (which needs a package-lock.json)
# doesn't fit. Instead we fetch it with a fixed-output derivation: `npm
# install` reaches the network during the build, and `manifest.hashes`
# pins the resulting store path per-platform.
#
# Per-platform hashes are required because a transitive dep
# (sherpa-onnx-node) uses npm `optionalDependencies` to ship native
# binaries keyed by OS+CPU, so the resolved tree (and FOD hash) differs
# across platforms. update.sh refreshes just the current host's entry;
# bumping `version` clears the rest, since other platforms must rebuild.
#
# A FOD must not reference other store paths, so the npm install and the
# node wrapper live in two derivations: `deps` is the pure FOD (just the
# installed tree), and the outer derivation wraps it with the pinned
# node — needed because systemd/launchd start with no node on PATH.
{
  lib,
  stdenvNoCC,
  nodejs,
  makeWrapper,
  cacert,
}:
let
  manifest = lib.importJSON ./manifest.json;
  system = stdenvNoCC.hostPlatform.system;
  hash = manifest.hashes.${system} or (throw ''
    paseo: no FOD hash recorded for ${system}.
    Run ./pkgs/paseo/update.sh on a ${system} host to populate it.
  '');

  deps = stdenvNoCC.mkDerivation {
    pname = "paseo-deps";
    inherit (manifest) version;

    dontUnpack = true;
    dontConfigure = true;

    strictDeps = true;
    nativeBuildInputs = [ nodejs cacert ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = hash;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      export npm_config_cache=$TMPDIR/npm-cache
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

      npm install \
        --global \
        --prefix $out \
        --no-audit \
        --no-fund \
        --no-update-notifier \
        "@getpaseo/cli@${manifest.version}"

      runHook postBuild
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "paseo";
  inherit (manifest) version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    # Run the pinned node against the ESM entry; the dependency tree
    # sits alongside it in the deps store path, so node resolves it.
    makeWrapper ${nodejs}/bin/node $out/bin/paseo \
      --add-flags "--disable-warning=DEP0040 ${deps}/lib/node_modules/@getpaseo/cli/dist/index.js" \
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
