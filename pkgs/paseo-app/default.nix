# Paseo desktop app, built from @maxfangx's fork releases
# (`maxfangx-v*` tags on MaxFangX/paseo). Unsigned personal build;
# nix's fetchurl never sets the quarantine xattr, so Gatekeeper does
# not block it. Installed via home.packages + targets.darwin.copyApps.
# Update with `just update paseo-app`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  source = lib.importJSON ./source.json;
in
stdenvNoCC.mkDerivation {
  pname = "paseo-app";
  inherit (source) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  # The zip holds Paseo.app at its root.
  sourceRoot = "Paseo.app";

  nativeBuildInputs = [ unzip ];

  dontBuild = true;
  dontStrip = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications/Paseo.app"
    cp -R . "$out/Applications/Paseo.app"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Paseo desktop app (personal fork build)";
    homepage = "https://github.com/MaxFangX/paseo";
    platforms = [ "aarch64-darwin" ];
  };
}
