# max2022 — macOS dev machine
{
  pkgs,
  lib,
  sources,
  buzz,
  ...
}:
{
  imports = [
    ./mods/dev-lexe.nix
  ];

  home.packages = [
    buzz # Buzz.app + `buzz-desktop` (see pkgs/buzz)
  ];

  # Copy .app bundles into ~/Applications/Home Manager Apps instead of
  # symlinking them; Spotlight doesn't index symlinked apps.
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  homebrew.casks = [
    "halloy"
    "orbstack"
    "qlcolorcode"
    "qlimagesize"
    "qlmarkdown"
    "qlstephen"
    "quicklook-video"
    "quicklook-json"
    "quicklookase"
    "rar"
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
    "Library/Application Support/iTerm2/DynamicProfiles/maxfangx.json"
      .source = ../iterm2-profile-maxfangx.json;
  };
}
