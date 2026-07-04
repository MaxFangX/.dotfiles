# Update with `nix-shell pkgs/update.nix --argstr package jj`
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  mold,
  git,
  gnupg,
  openssh,
}:
let
  source = lib.importJSON ./source.json;
in
rustPlatform.buildRustPackage {
  pname = "jujutsu";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "jj-vcs";
    repo = "jj";
    rev = "v${source.version}";
    inherit (source) hash;
  };

  # Vendor deps from the lockfile so updates don't need a
  # separate cargoHash. Kept in sync by update.sh.
  cargoLock.lockFile = ./Cargo.lock;

  # Only the `jj` binary; skip the fake editors used in tests.
  cargoBuildFlags = [ "--bin" "jj" ];

  nativeBuildInputs =
    [ installShellFiles ]
    ++ lib.optionals stdenv.isLinux [ mold ];

  # jj's suite is large and shells out to git/gnupg/ssh; skip it to
  # keep `hms` rebuilds fast. These stay for reference / re-enabling.
  doCheck = false;
  nativeCheckInputs = [ git gnupg openssh ];

  env.CARGO_INCREMENTAL = "0"; # rust-lang/rust#139110
  env.RUSTFLAGS =
    lib.optionalString stdenv.isLinux "-C link-arg=-fuse-ld=mold";

  postInstall = ''
    $out/bin/jj util install-man-pages man
    installManPage ./man/man1/*

    installShellCompletion --cmd jj \
      --bash <(COMPLETE=bash $out/bin/jj) \
      --fish <(COMPLETE=fish $out/bin/jj) \
      --zsh <(COMPLETE=zsh $out/bin/jj)
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Git-compatible DVCS that is both simple and powerful";
    homepage = "https://github.com/jj-vcs/jj";
    license = lib.licenses.asl20;
    mainProgram = "jj";
    platforms = lib.platforms.unix;
  };
}
