# iOS/macOS tooling for Lexe app development.
# Requires Xcode to be installed separately via App Store.
#
# Note: xcodebuild requires a macOS-compatible rsync. The platform-aware
# rsync wrapper is provided by pkgs/rsync.nix and installed via dev.nix.
{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;

  # Expected Xcode/SDK versions - keep synced with Lexe's devshell
  xcodeVersion = "26.4.1";
  macOsSdkVersion = "26.4";
  iOsSdkVersion = "26.4";

  # Xcode validation script - warns if versions don't match Lexe's expected
  xcodeValidation = pkgs.writeShellScript "xcode-validation" ''
    if [[ ! -d /Applications/Xcode.app ]]; then
      echo >&2 "warning: Xcode not installed (/Applications/Xcode.app missing)"
      return
    fi

    actualXcodeVers="$(plutil -extract CFBundleShortVersionString \
      raw -n -o - /Applications/Xcode.app/Contents/version.plist)"
    if [[ "$actualXcodeVers" != "${xcodeVersion}" ]]; then
      echo >&2 "warning: Xcode version mismatch"
      echo >&2 "    actual: $actualXcodeVers"
      echo >&2 "  expected: ${xcodeVersion}"
    fi

    if [[ "$(command -v xcodebuild)" != "/usr/bin/xcodebuild" ]]; then
      echo >&2 "warning: xcodebuild not at /usr/bin/xcodebuild"
      echo >&2 "    actual: $(command -v xcodebuild || echo '(not found)')"
    fi
  '';
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
    # Expected versions for Lexe builds
    LEXE_XCODE_VERSION = xcodeVersion;
    LEXE_MACOS_SDK_VERSION = macOsSdkVersion;
    LEXE_IOS_SDK_VERSION = iOsSdkVersion;
  };

  # Install validation script to be sourced from shell/common.sh
  home.file.".local/lib/xcode-validation.sh" = lib.mkIf isDarwin {
    source = xcodeValidation;
  };
}
