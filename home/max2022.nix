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

  # macOS rewrites a quick double-space as ". " (System Settings >
  # Keyboard > Input Sources > Edit > "Add period with double-space").
  # That injects a stray `.` into nvim's <Space><Space> leader chord,
  # where normal-mode `.` silently repeats the last change. Disabled for
  # iTerm2 only, so the substitution still works in prose apps.
  targets.darwin.defaults."com.googlecode.iterm2"
    .NSAutomaticPeriodSubstitutionEnabled = false;

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
