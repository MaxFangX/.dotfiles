# max-nitropad-2024 — Linux personal machine
{ pkgs, ... }:
{
  imports = [
    ./mods/core.nix
  ];

  home.username = "max";
  home.homeDirectory = "/home/max";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.signal-desktop
  ];
}
