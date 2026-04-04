# iOS/macOS tooling for Lexe app development.
# Requires Xcode to be installed separately via App Store.
#
# Note: xcodebuild requires a macOS-compatible rsync. The platform-aware
# rsync wrapper is provided by pkgs/rsync.nix and installed via dev.nix.
{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.packages = lib.optionals isDarwin [
    pkgs.cocoapods # pod - iOS dependency manager
    pkgs.fastlane # App deploy tooling
    pkgs.libimobiledevice # idevicesyslog - view logs from iOS device
  ];

  home.sessionVariables = lib.mkIf isDarwin {
    # Fastlane requires UTF-8 locale for uploads
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
