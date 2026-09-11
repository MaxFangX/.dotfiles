# Update with `./pkgs/buzz/update.sh`
{
  lib,
  stdenv,
  callPackage,
  claude-agent-acp,
  codex-acp,
  fetchFromGitHub,
  makeBinaryWrapper,
  rust,
  rustPlatform,

  cargo-tauri,
  pnpm_11,
  wrapGAppsHook4,

  alsa-lib,
  glib-networking,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libopus,
  librsvg,
  openssl,
  webkitgtk_4_1,
  xdotool,
}:

let
  version = "0.5.20-unstable-2026-08-27";
  # Temporarily built from benthecarman's fork with bugfixes.
  # TODO(max): Switch back to block/buzz release tags once upstreamed.
  src = fetchFromGitHub {
    owner = "benthecarman";
    repo = "buzz";
    rev = "bb79de61d24569c86c87d70aa4db8155bc3ef398";
    hash = "sha256-2Uu528ywMCK9w4LTADUfOh1noX0lUGBnx2HQYjWOzzE=";
  };

  pnpm = pnpm_11;
  targetTriple = rust.envVars.rustHostPlatformSpec;

  # Libraries the desktop binary links against on Linux. desktop.nix
  # compiles against them; the bundle below re-lists them so its
  # wrapper exposes them (plus GStreamer media plugins) at runtime.
  linuxDesktopLibs = [
    alsa-lib
    glib-networking
    gtk3
    libayatana-appindicator
    libopus
    librsvg
    openssl
    webkitgtk_4_1
    xdotool
  ];
  # Must mirror bundle.externalBin in desktop/src-tauri/tauri.conf.json.
  # `buzz` is the CLI binary, built from the buzz-cli crate.
  sidecarNames = [
    "buzz-acp"
    "buzz-agent"
    "buzz-backend-kubernetes"
    "buzz-dev-mcp"
    "git-credential-nostr"
    "buzz"
  ];
  acpBinsPath = lib.makeBinPath [
    claude-agent-acp
    codex-acp
  ];

  frontend = callPackage ./frontend.nix {
    inherit
      pnpm
      src
      version
      ;
  };
  sidecars = callPackage ./sidecars.nix { inherit src version; };
  desktop = callPackage ./desktop.nix {
    inherit
      frontend
      linuxDesktopLibs
      sidecarNames
      src
      version
      ;
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "buzz";
  inherit src version;

  # cargo-tauri bundle still reads Cargo metadata, but reuses the independently
  # compiled desktop executable instead of invoking Cargo's build command.
  cargoRoot = "desktop/src-tauri";
  cargoDeps = desktop.cargoDeps;
  cargoBuildType = "release";
  tauriBundleType = if stdenv.hostPlatform.isLinux then "deb" else "app";

  nativeBuildInputs = [
    cargo-tauri.hook
    rustPlatform.cargoSetupHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ makeBinaryWrapper ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux (
    linuxDesktopLibs
    ++ [
      # WebKit aborts if its GStreamer media elements are missing at runtime.
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gstreamer
    ]
  );

  buildPhase = ''
    runHook preBuild

    export CARGO_TARGET_DIR="$PWD/target"
    targetDir="$CARGO_TARGET_DIR/${targetTriple}/release"

    mkdir -p \
      "$targetDir" \
      desktop/dist \
      desktop/src-tauri/binaries
    install -m755 \
      "${desktop}/bin/buzz-desktop" \
      "$targetDir/buzz-desktop"
    cp -R "${frontend}/." desktop/dist/

    for sidecar in ${lib.escapeShellArgs sidecarNames}; do
      install -m755 \
        "${sidecars}/bin/$sidecar" \
        "desktop/src-tauri/binaries/$sidecar-${targetTriple}"
    done

    pushd desktop/src-tauri
    cargo tauri bundle \
      --bundles "$tauriBundleType" \
      --ci \
      --no-sign \
      --target ${targetTriple}
    popd

    runHook postBuild
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    # LaunchServices starts the app-bundle executable directly.
    appExecutable="$out/Applications/Buzz.app/Contents/MacOS/buzz-desktop"
    mv "$appExecutable" "$appExecutable.unwrapped"
    makeBinaryWrapper \
      "$appExecutable.unwrapped" \
      "$appExecutable" \
      --suffix PATH : ${lib.escapeShellArg acpBinsPath}

    mkdir -p "$out/bin"
    ln -s "$appExecutable" "$out/bin/buzz-desktop"
  '';

  # Keep CLI sidecars unwrapped so Tauri can execute their adjacent binaries.
  dontWrapGApps = true;
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Buzz discovers ACP adapters from its process PATH. Keep the packaged
    # adapters private to the desktop instead of exposing them in $out/bin.
    wrapGApp "$out/bin/buzz-desktop" \
      --suffix PATH : ${lib.escapeShellArg acpBinsPath}
  '';

  passthru = {
    inherit desktop frontend sidecars;
    tests = lib.optionalAttrs stdenv.hostPlatform.isLinux {
      headless = callPackage ./headless-test.nix {
        buzz = finalAttrs.finalPackage;
      };
    };
    updateScript = ./update.sh;
  };

  meta = {
    description = "Workspace where humans and agents build together";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    mainProgram = "buzz-desktop";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
})
