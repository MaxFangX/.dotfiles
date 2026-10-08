{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  versionCheckHook,
}:
let
  hostPlatform = stdenv.hostPlatform;
  sources = lib.importJSON ./sources.json;
  source = sources.${hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "goose";
  inherit (sources) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  dontBuild = true;

  # The Linux build is a glibc binary that also links libstdc++.
  strictDeps = true;
  nativeBuildInputs = lib.optionals hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm 755 goose $out/bin/goose
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Block's goose AI agent CLI";
    homepage = "https://github.com/aaif-goose/goose";
    mainProgram = "goose";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
