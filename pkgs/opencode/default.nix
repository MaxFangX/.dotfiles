# OpenCode: open-source terminal coding agent with multi-provider model
# support. nixpkgs lags far behind upstream, so take the prebuilt
# bun-compiled binary from GitHub releases. Update with
# `just update opencode`.
{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  unzip,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  hostPlatform = stdenv.hostPlatform;
  sources = lib.importJSON ./sources.json;
  source = sources.${hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit (sources) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  dontBuild = true;
  # Otherwise the bun runtime is stripped out of the binary.
  dontStrip = true;

  # The Linux build is a glibc binary that also links libstdc++.
  strictDeps = true;
  nativeBuildInputs =
    lib.optionals hostPlatform.isDarwin [ unzip ]
    ++ lib.optionals hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm 755 opencode $out/bin/opencode
    runHook postInstall
  '';

  # opencode --version writes under $HOME, so give it a scratch one.
  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Open-source terminal coding agent";
    homepage = "https://opencode.ai";
    mainProgram = "opencode";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
