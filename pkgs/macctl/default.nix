# macOS window control for AI agents; see README.md.
#
# Built with one swiftc call rather than swiftpm: there are no
# dependencies, and Package.swift is only for `swift build` and
# SourceKit-LSP.
{
  lib,
  stdenv,
  swift,
  apple-sdk,
}:
stdenv.mkDerivation {
  pname = "macctl";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Package.swift
      ./Sources
    ];
  };

  nativeBuildInputs = [ swift ];
  buildInputs = [ apple-sdk ];

  buildPhase = ''
    runHook preBuild

    swiftc -O -module-name macctl -o macctl Sources/macctl/*.swift \
      -framework AppKit -framework ApplicationServices \
      -framework CoreGraphics -framework ImageIO

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 macctl "$out/bin/macctl"

    runHook postInstall
  '';

  meta = {
    description = "macOS window capture and input for AI agents";
    mainProgram = "macctl";
    platforms = lib.platforms.darwin;
  };
}
