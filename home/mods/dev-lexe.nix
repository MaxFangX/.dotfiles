# Lexe-specific dev environment.
# Adds Flutter, Android SDK, PostgreSQL, and related tooling
# on top of the general dev module.
{ pkgs, ... }:
{
  imports = [
    ./dev.nix
    ./dev-lexe/android.nix
    ./dev-lexe/postgres.nix
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
    pkgs.flutter # App tests + screenshot generation
    pkgs.jdk17_headless # Android builds
    pkgs.oxipng # PNG optimization (screenshots)
    pkgs.protobuf # aesm-client build script
    pkgs.shellcheck # Shell script linter
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk17_headless.home}";
  };
}
