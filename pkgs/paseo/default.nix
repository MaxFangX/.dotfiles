# Paseo, from @maxfangx's fork releases (`maxfangx-v*` tags on
# MaxFangX/paseo; see scripts/fork/RELEASE.md there). One release pins
# everything, so the CLI always matches the daemon and the app:
#
#  - The CLI and daemon (`paseo`), on every host. Each release ships the
#    seven npm packages behind them as tarballs, and package.json depends
#    on all seven. The CLI and server pin their siblings by exact version
#    (e.g. "@getpaseo/server": "0.11.2"), which the fork's top-level
#    copies satisfy, so npm never pulls upstream's from the registry.
#    (`overrides` would say this more directly, but importNpmLock leaves
#    their URLs in place and the offline install then fails to fetch
#    them.) The lockfile records every dependency's `integrity` hash, and
#    importNpmLock fetches each one using those hashes, so there is no
#    separately-maintained Nix hash. The lock lists every platform's
#    optional native deps (e.g. sherpa-onnx-*); only the ones matching
#    the build host are fetched.
#
#  - The desktop app, on aarch64-darwin only (the fork builds no other).
#    Unsigned personal build; nix's fetchurl never sets the quarantine
#    xattr, so Gatekeeper does not block it. Lands in
#    ~/Applications/Home Manager Apps via targets.darwin.copyApps.
#
# Update with `just update paseo` (pins the latest release and regenerates
# the lockfile). node is wrapped in because systemd/launchd start the
# daemon with no node on PATH.
#
# package.json overrides uuid to ^11.1.1 (CVE-2026-41907; @getpaseo/server
# wants ^9, but only uses `v4`, which is unchanged). Drop the override once
# the server requires uuid >= 11.1.1.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  nodejs,
  makeWrapper,
  importNpmLock,
}:
let
  source = lib.importJSON ./source.json;

  nodeModules = importNpmLock.buildNodeModules {
    npmRoot = ./.;
    inherit nodejs;
  };

  withApp = stdenvNoCC.hostPlatform.system == "aarch64-darwin";
  app = fetchurl { inherit (source.app) url hash; };
in
stdenvNoCC.mkDerivation {
  pname = "paseo";
  inherit (source) version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # Fixup would patch the app's scripts and strip its binaries, breaking
  # its signature. The CLI wrapper needs none.
  dontFixup = true;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional withApp unzip;

  installPhase = ''
    runHook preInstall

    # Run the pinned node against the ESM entry; the dependency tree
    # sits alongside it in node_modules, so node resolves it.
    makeWrapper ${nodejs}/bin/node $out/bin/paseo \
      --add-flags "--disable-warning=DEP0040 ${nodeModules}/node_modules/@getpaseo/cli/dist/index.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  ''
  # The zip holds Paseo.app at its root, beside a __MACOSX dir.
  + lib.optionalString withApp ''
    unzip -q ${app} -d app
    mkdir -p $out/Applications
    cp -R app/Paseo.app $out/Applications/
  ''
  + ''
    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Paseo CLI, daemon, and desktop app (personal fork build)";
    homepage = "https://github.com/MaxFangX/paseo";
    mainProgram = "paseo";
    platforms = lib.platforms.unix;
  };
}
