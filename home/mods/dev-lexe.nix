# Lexe-specific dev environment.
# Adds Flutter, Android SDK, PostgreSQL, and related tooling
# on top of the general dev module.
{ lib, pkgs, ... }:
{
  imports = [
    ./dev.nix
    ./dev-lexe/android.nix
    ./dev-lexe/ios.nix
    ./dev-lexe/postgres.nix
  ];

  # macOS-only: Homebrew packages
  homebrew = lib.mkIf pkgs.stdenv.isDarwin {
    taps = [
      "MaterializeInc/homebrew-crosstools" # SGX cross-compilation
    ];
    brews = [
      "libfido2" # YubiKey FIDO2 support for SSH
      "materializeinc/crosstools/x86_64-unknown-linux-gnu"
    ];
  };

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
    pkgs.flutter332 # Pinned to match lexe repo (Dart 3.8.1)
    pkgs.jdk17_headless # Android builds
    pkgs.oxipng # PNG optimization (screenshots)
    pkgs.protobuf # aesm-client build script
    pkgs.shellcheck # Shell script linter
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk17_headless.home}";
  };
}
