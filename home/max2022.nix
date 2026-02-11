{
  pkgs,
  lib,
  sources,
  ...
}:
{
  imports = [
    ./mods/core.nix
    ./mods/dev.nix
  ];

  home.username = "fang";
  home.homeDirectory = "/Users/fang";
  home.stateVersion = "25.05";

  home.file = {
    ".ideavimrc".source = ../nvim/init.lua;
    ".config/karabiner/assets/complex_modifications"
      .source =
      ../karabiner/assets/complex_modifications;
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Application Support/Code/User/settings.json"
      .source = ../vscode/settings.json;
    "Library/Application Support/Code/User/keybindings.json"
      .source = ../vscode/keybindings.json;
  };
}
