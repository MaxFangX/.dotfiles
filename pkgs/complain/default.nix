{ lib, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "complain";
  version = (lib.importTOML ./Cargo.toml).package.version;
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./Cargo.toml ./Cargo.lock ./src ];
  };
  cargoLock.lockFile = ./Cargo.lock;
  meta = {
    description = "Let agents file complaints about their tooling";
    mainProgram = "complain";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
