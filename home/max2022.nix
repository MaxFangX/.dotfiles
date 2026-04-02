# max2022 — macOS dev machine
{
  pkgs,
  lib,
  sources,
  ...
}:
{
  imports = [
    ./mods/dev-lexe
  ];

  home.username = "fang";
  home.homeDirectory = "/Users/fang";
  home.stateVersion = "25.05";

  home.sessionPath = [
    "$HOME/.lmstudio/bin"
  ];

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
    "Library/Application Support/iTerm2/DynamicProfiles/maxfangx.json"
      .source = ../iterm2-profile-maxfangx.json;
  };
}
