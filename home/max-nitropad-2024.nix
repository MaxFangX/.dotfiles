# max-nitropad-2024 — Linux personal machine
{ pkgs, ... }:
let
  formFeed = builtins.fromJSON ''"\u000c"'';
in
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
        {
          key = "K";
          mods = "Control|Shift";
          mode = "~Vi|~Search";
          chars = formFeed;
        }
        {
          key = "K";
          mods = "Control|Shift";
          mode = "~Vi|~Search";
          action = "ClearHistory";
        }
      ];
    };
  };

  home.username = "max";
  home.homeDirectory = "/home/max";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.fastmod
    pkgs.gh
    pkgs.signal-desktop
    pkgs.toml-cli
  ];
}
