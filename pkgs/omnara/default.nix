{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeBinaryWrapper,
  stdenvNoCC,
  versionCheckHook,
}:
let
  hostPlatform = stdenvNoCC.hostPlatform;
  sources = lib.importJSON ./sources.json;
  source = sources.${hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "omnara";
  inherit (source) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  strictDeps = true;
  nativeBuildInputs = [
    makeBinaryWrapper
  ]
  ++ lib.optionals hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm 755 $src $out/bin/omnara

    wrapProgram $out/bin/omnara \
      --set OMNARA_NO_UPDATE 1

    runHook postInstall
  '';

  dontStrip = true;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Omnara CLI";
    homepage = "https://omnara.com";
    mainProgram = "omnara";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
