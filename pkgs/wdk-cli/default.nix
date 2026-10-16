# Tether WDK CLI (@tetherto/wdk-cli): `wdk`, `wdk-daemon`, `wdk-mcp`.
#
# A self-custodial multi-chain wallet CLI for agents (EVM, Solana, Tron,
# Spark, Bitcoin). Same packaging as paseo: a committed package.json pins
# the version and importNpmLock fetches the dependency tree from the
# generated package-lock.json's integrity hashes, so there is no separate
# Nix hash. Update with `just update wdk-cli`.
#
# The wallet itself (seed, passphrase, token registry) is per-machine
# state; see ~/max2022 (`wdk-up`, the agent-wallet skill).
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
  pkgDir = "${nodeModules}/node_modules/@tetherto/wdk-cli";
  bins = [ "wdk" "wdk-daemon" "wdk-mcp" ];
in
stdenvNoCC.mkDerivation {
  pname = "wdk-cli";
  version =
    (lib.importJSON ./package-lock.json)
    .packages."node_modules/@tetherto/wdk-cli".version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  # Upstream's bin stubs run node with --disable-warning=ExperimentalWarning.
  installPhase = ''
    runHook preInstall
    ${lib.concatMapStringsSep "\n" (bin: ''
      makeWrapper ${nodejs}/bin/node $out/bin/${bin} \
        --add-flags "--disable-warning=ExperimentalWarning ${pkgDir}/bin/${bin}.mjs" \
        --prefix PATH : ${lib.makeBinPath [ nodejs ]}
    '') bins}
    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Tether Wallet Development Kit CLI (@tetherto/wdk-cli)";
    homepage = "https://github.com/tetherto/wdk-cli";
    license = lib.licenses.asl20;
    mainProgram = "wdk";
    platforms = lib.platforms.unix;
  };
}
