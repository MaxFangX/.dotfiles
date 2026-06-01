{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeBinaryWrapper,
  stdenvNoCC,
  unzip,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  hostPlatform = stdenvNoCC.hostPlatform;
  sources = lib.importJSON ./sources.json;
  source = sources.${hostPlatform.system};

  # Suppress the interactive updater and dead-end its release
  # URL — nix owns the CLI version. The daemon ignores
  # OMNARA_NO_UPDATE; its updates are handled by the service
  # (see home/mods/omnara.nix).
  wrapperArgs = lib.concatStringsSep " " [
    "--set OMNARA_NO_UPDATE 1"
    "--set OMNARA_RELEASE_URL http://localhost:6969"
  ];

  # macOS ships the CLI inside an .app bundle zip; Linux ships
  # a bare binary. The bun executable only runs from within its
  # bundle (standalone it silently no-ops), so we keep the
  # bundle and point bin/omnara into it. We first rename it off
  # the .app extension, which macOS locks with a flag nix can't
  # clear at store registration; CFBundle resolves via the
  # Contents/MacOS layout, not the extension.
  appDirInZip = "Omnara-${source.target}.app";
  bundleDir = "omnara-bundle";
  bundleBinary = "${bundleDir}/Contents/MacOS/omnara";
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
  ++ lib.optionals hostPlatform.isDarwin [ unzip ]
  ++ lib.optionals hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    ${
      if hostPlatform.isDarwin then ''
        mkdir -p $out/libexec
        unzip -q $src -d $out/libexec
        mv $out/libexec/${appDirInZip} $out/libexec/${bundleDir}
        makeWrapper $out/libexec/${bundleBinary} \
          $out/bin/omnara ${wrapperArgs}
      '' else ''
        install -Dm 755 $src $out/bin/omnara
        wrapProgram $out/bin/omnara ${wrapperArgs}
      ''
    }

    runHook postInstall
  '';

  dontStrip = true;

  # omnara is a bun single-file executable that unpacks
  # itself to $HOME at runtime, so the check needs a
  # writable home.
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
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
