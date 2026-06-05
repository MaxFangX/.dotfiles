# Update with `nix-shell pkgs/update.nix --argstr package git-hunk`
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  git,
}:
let
  source = lib.importJSON ./source.json;
in
rustPlatform.buildRustPackage {
  pname = "git-hunk";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "nexxeln";
    repo = "git-hunk";
    rev = "v${source.version}";
    inherit (source) hash;
  };

  # Vendor deps from the lockfile so updates don't need a
  # separate cargoHash. Kept in sync by update.sh.
  cargoLock.lockFile = ./Cargo.lock;

  # The CLI integration tests shell out to `git`.
  nativeCheckInputs = [ git ];

  # Expose the Claude Code skill so home-manager can symlink it,
  # pinned to the same version as the binary.
  postInstall = ''
    install -Dm644 SKILL.md "$out/share/git-hunk/SKILL.md"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Non-interactive hunk staging for AI agents";
    homepage = "https://github.com/nexxeln/git-hunk";
    license = lib.licenses.asl20;
    mainProgram = "git-hunk";
    platforms = lib.platforms.unix;
  };
}
