{
  autoPatchelfHook,
  fetchurl,
  lib,
  libcap,
  openssl,
  stdenv,
  versionCheckHook,
  zlib,
}:
let
  hostPlatform = stdenv.hostPlatform;
  sources = lib.importJSON ./sources.json;
  source = sources.${hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "codex";
  inherit (sources) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  dontBuild = true;
  dontStrip = true;

  strictDeps = true;
  nativeBuildInputs =
    lib.optionals hostPlatform.isLinux [
      autoPatchelfHook
    ];

  buildInputs = lib.optionals hostPlatform.isLinux [
    libcap
    openssl
    stdenv.cc.cc.lib # libgcc_s
    zlib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm 755 codex-${source.target} \
      $out/bin/codex
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "OpenAI Codex CLI";
    homepage = "https://github.com/openai/codex";
    mainProgram = "codex";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
