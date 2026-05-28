{
  bubblewrap,
  fetchurl,
  lib,
  makeBinaryWrapper,
  stdenv,
  versionCheckHook,
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

  # The Linux build is a statically linked musl binary, so it needs no
  # patchelf. Wrap it with bubblewrap on PATH for codex's sandbox.
  strictDeps = true;
  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm 755 codex-${source.target} \
      $out/bin/${if hostPlatform.isLinux then "codex-unwrapped" else "codex"}
    runHook postInstall
  '';

  postInstall = lib.optionalString hostPlatform.isLinux ''
    makeBinaryWrapper $out/bin/codex-unwrapped $out/bin/codex \
      --prefix PATH : ${lib.makeBinPath [ bubblewrap ]}
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
