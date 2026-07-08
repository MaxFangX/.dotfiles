# Update with `nix-shell pkgs/update.nix --argstr package jj-hunk-tool`
#
# Built from @maxfangx's fork. Pinned by commit rev, not a release tag,
# since the fork has no releases (cf. pkgs/git-hunk, which pins a tag).
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  jujutsu,
}:
let
  source = lib.importJSON ./source.json;
in
rustPlatform.buildRustPackage {
  pname = "jj-hunk-tool";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "MaxFangX";
    repo = "jj-hunk-tool";
    inherit (source) rev hash;
  };

  # Vendor deps from the lockfile so updates don't need a
  # separate cargoHash. Kept in sync by update.sh.
  cargoLock.lockFile = ./Cargo.lock;

  # The CLI integration tests shell out to `jj`.
  nativeCheckInputs = [ jujutsu ];

  # Expose the agent skills so home-manager can symlink them, pinned to
  # the same version as the binary.
  postInstall = ''
    mkdir -p "$out/share/jj-hunk-tool"
    cp -r skills "$out/share/jj-hunk-tool/skills"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Hunk-level operations for jj (jujutsu)";
    homepage = "https://github.com/mvzink/jj-hunk-tool";
    license = lib.licenses.mit;
    mainProgram = "jj-hunk-tool";
    platforms = lib.platforms.unix;
  };
}
