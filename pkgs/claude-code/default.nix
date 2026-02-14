# Update with `./pkgs/claude-code/update.sh`
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  stdenv = stdenvNoCC;
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  manifest = lib.importJSON ./manifest.json;
  platformKey =
    {
      "aarch64-darwin" = "darwin-arm64";
      "x86_64-linux" = "linux-x64";
    }
    .${stdenv.hostPlatform.system};
  platformManifestEntry =
    manifest.platforms.${platformKey};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  inherit (manifest) version;

  src = fetchurl {
    url = "${baseUrl}/${finalAttrs.version}/${platformKey}/claude";
    sha256 = platformManifestEntry.checksum;
  };

  dontUnpack = true;
  dontBuild = true;
  # Otherwise the bun runtime is executed instead
  # of the binary.
  dontStrip = true;

  strictDeps = true;
  nativeBuildInputs =
    [ makeBinaryWrapper ]
    ++ lib.optionals stdenv.hostPlatform.isElf [
      autoPatchelfHook
    ];

  installPhase = ''
    runHook preInstall

    install -Dm 755 $src $out/bin/claude

    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            procps
            ripgrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram =
    "${placeholder "out"}/bin/claude";
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Claude Code CLI";
    homepage = "https://github.com/anthropics/claude-code";
    mainProgram = "claude";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
