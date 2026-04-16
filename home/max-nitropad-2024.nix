# max-nitropad-2024 — Linux personal machine
{ pkgs, ... }:
{
  imports = [
    ./mods/core.nix
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      window.dimensions = {
        columns = 103;
        lines = 19;
      };

      keyboard.bindings = [
        {
          key = "N";
          mods = "Control|Shift";
          action = "CreateNewWindow";
        }
      ];
    };
  };

  home.username = "max";
  home.homeDirectory = "/home/max";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.signal-desktop
  ];
}
