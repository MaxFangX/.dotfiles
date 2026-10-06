# Kimi Code CLI: Moonshot AI's terminal coding agent.
#
# Upstream ships a bun-compiled single binary per platform,
# zstd-compressed alongside a release `manifest.json` that pins the
# version, tag, and per-asset sha256. We vendor that manifest verbatim,
# so there is no separate Nix hash. Update with `just update kimi-code`.
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  zstd,
  makeBinaryWrapper,
  autoPatchelfHook,
  fd,
  git,
  ripgrep,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  manifest = lib.importJSON ./manifest.json;
  platformKey =
    {
      "aarch64-darwin" = "darwin-arm64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-linux" = "linux-x64";
    }
    .${stdenvNoCC.hostPlatform.system};
  platform = manifest.platforms.${platformKey};

  # The release tag embeds a scoped npm name
  # (`@moonshot-ai/kimi-code@0.31.1`), so its `/` must be
  # percent-encoded to stay one path segment in the asset URL.
  tag = lib.replaceStrings [ "/" ] [ "%2F" ] manifest.tag;
in
stdenvNoCC.mkDerivation {
  pname = "kimi-code";
  inherit (manifest) version;

  # Only compressed assets are hosted; the `.zst` unpacks to the bare
  # binary whose hash is the manifest's top-level `checksum`.
  src = fetchurl {
    url =
      "https://github.com/MoonshotAI/kimi-code/releases/download"
      + "/${tag}/${platform.compressed.filename}";
    sha256 = platform.compressed.checksum;
  };

  dontUnpack = true;
  dontBuild = true;
  # Otherwise the bun runtime is stripped out of the binary.
  dontStrip = true;

  strictDeps = true;
  nativeBuildInputs =
    [
      makeBinaryWrapper
      zstd
    ]
    ++ lib.optionals stdenvNoCC.hostPlatform.isElf [
      autoPatchelfHook
    ];

  # The bun runtime links against libstdc++/libgcc_s; autoPatchelfHook
  # resolves them from here on ELF platforms.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isElf [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    zstd -d $src -o kimi
    install -Dm 755 kimi $out/bin/kimi

    # kimi downloads its own rg/fd into ~/.kimi-code/bin when they
    # are missing from PATH; supply them from the store instead.
    wrapProgram $out/bin/kimi \
      --set KIMI_CODE_NO_AUTO_UPDATE 1 \
      --set KIMI_DISABLE_TELEMETRY 1 \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          git
          ripgrep
        ]
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Kimi Code CLI";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    mainProgram = "kimi";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
