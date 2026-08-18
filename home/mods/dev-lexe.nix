# Lexe-specific dev environment.
# Adds Flutter, Android SDK, PostgreSQL, and related tooling
# on top of the general dev module.
{ lib, pkgs, sources, ... }:
let
  # Flutter 3.41 isn't in nixos-25.11; pull it from the 26.05 channel,
  # matching the lexe repo's nixpkgs pin.
  pkgs2605 = import sources.nixpkgs-2605 {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
  flutter = pkgs2605.flutter341;
in
{
  imports = [
    ./dev.nix
    ./dev-lexe/android.nix
    ./dev-lexe/ios.nix
    ./dev-lexe/postgres.nix
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    ./dev-lexe/homebrew.nix
  ];

  # PostgreSQL 17 for Lexe local development
  services.postgres = {
    enable = true;
    ensureUsers = [
      { name = "lxuser1"; password = "sadge"; }
      { name = "lxuser2"; password = "sadge"; }
    ];
    ensureDatabases = [
      { name = "lexe-dev-db1"; owner = "lxuser1"; }
      { name = "lexe-dev-db2"; owner = "lxuser2"; }
    ];
  };

  home.packages = [
    pkgs.azure-cli # Azure resource management
    pkgs.cmake # flutter_zxing NDK build
    flutter # Pinned to match lexe repo (3.41.9, Dart 3.11.5)
    pkgs.jdk17_headless # Android builds
    pkgs.oxipng # PNG optimization (screenshots)
    pkgs.protobuf # aesm-client build script
    pkgs.shellcheck # Shell script linter
  ];

  home.sessionVariables = {
    FLUTTER_ROOT = "${flutter}";
    GRADLE_USER_HOME = "$HOME/.gradle";
    JAVA_HOME = "${pkgs.jdk17_headless.home}";
  };
}
