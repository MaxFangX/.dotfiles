# Update with `nix-shell pkgs/update.nix --argstr package jj-hunk-tool`
#
# Built from @maxfangx's fork. Prefers the local checkout at
# ~/dev/forks/jj-hunk-tool when present (including unpushed commits and
# dirty tracked files); otherwise builds the pinned GitHub rev. Pinned by
# commit rev, not a release tag, since the fork has no releases
# (cf. pkgs/git-hunk, which pins a tag).
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  jujutsu,
}:
let
  source = lib.importJSON ./source.json;
  localRepo = /Users/fang/dev/forks/jj-hunk-tool;
  useLocal = builtins.pathExists localRepo;
in
rustPlatform.buildRustPackage {
  pname = "jj-hunk-tool";
  version = if useLocal then "${source.version}-local" else source.version;

  # fetchGit (vs a raw path) copies only git-tracked files into the store,
  # excluding target/ and other untracked junk.
  src =
    if useLocal then
      builtins.fetchGit localRepo
    else
      fetchFromGitHub {
        owner = "MaxFangX";
        repo = "jj-hunk-tool";
        inherit (source) rev hash;
      };

  # Vendor deps from the lockfile so updates don't need a
  # separate cargoHash. The pinned copy is kept in sync by update.sh;
  # local builds use the local lockfile so they can't drift.
  cargoLock.lockFile =
    if useLocal then localRepo + "/Cargo.lock" else ./Cargo.lock;

  # The CLI integration tests shell out to `jj`.
  nativeCheckInputs = [ jujutsu ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Hunk-level operations for jj (jujutsu)";
    homepage = "https://github.com/mvzink/jj-hunk-tool";
    license = lib.licenses.mit;
    mainProgram = "jj-hunk-tool";
    platforms = lib.platforms.unix;
  };
}
