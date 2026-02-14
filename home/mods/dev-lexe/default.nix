# Lexe-specific dev environment.
# Adds Flutter, Android SDK, protobuf, PostgreSQL, and related
# tooling on top of the general dev module.
{ pkgs, ... }:
let
  # Android SDK — versions synced with public/nix/pkgs/default.nix
  androidSdk =
    (pkgs.androidenv.composeAndroidPackages {
      abiVersions = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86_64" # emulator on x86_64 hosts
      ];
      platformVersions = [
        "35" # lexe
        "34" # app_links, camera_android_camerax
      ];
      buildToolsVersions = [ "34.0.0" ];
      includeNDK = true;
      ndkVersion = "27.0.12077973";
      cmakeVersions = [ "3.22.1" ];
      includeEmulator = true;
      includeSystemImages = true;
      systemImageTypes = [ "google_apis" ];
    }).androidsdk;

  androidHome =
    "${androidSdk}/libexec/android-sdk";

  avdName = "lexe-screenshots";
  systemImage =
    "system-images;android-35;google_apis;x86_64";

  # Headless Android emulator launcher.
  # Creates the AVD on first run, then starts the emulator
  # and waits for the device to fully boot.
  android-emulator = pkgs.writeShellApplication {
    name = "android-emulator";
    runtimeInputs = [ androidSdk ];
    text = ''
      export ANDROID_HOME="${androidHome}"
      export ANDROID_SDK_ROOT="${androidHome}"

      # Create AVD if it doesn't exist
      if ! avdmanager list avd 2>/dev/null \
           | grep -q "Name: ${avdName}"; then
        echo "Creating AVD '${avdName}'..."
        echo "no" | avdmanager create avd \
          --name "${avdName}" \
          --package "${systemImage}" \
          --device "pixel_6"
      fi

      accel_flag=""
      if [ ! -e /dev/kvm ]; then
        echo "No KVM — using software emulation."
        accel_flag="-accel off"
      fi

      echo "Starting emulator..."
      # shellcheck disable=SC2086
      emulator -avd "${avdName}" \
        -no-window -no-audio -no-boot-anim \
        -no-snapshot -no-metrics \
        -gpu swiftshader_indirect \
        $accel_flag &
      EMU_PID=$!

      echo "Waiting for device..."
      adb wait-for-device

      echo "Waiting for boot (this may take a few min)..."
      # shellcheck disable=SC2016
      adb shell \
        'while [ "$(getprop sys.boot_completed)" != "1" ]
         do sleep 2; done'

      echo "Emulator ready (PID=$EMU_PID)."
      echo "Kill with: adb emu kill"
      wait "$EMU_PID"
    '';
  };
in
{
  imports = [
    ../dev.nix
    ./postgresql.nix
  ];

  home.packages = [
    pkgs.protobuf # aesm-client build script
    pkgs.flutter # App tests + screenshot generation
    pkgs.jdk17_headless # Android builds
    pkgs.oxipng # PNG optimization (screenshots)
    androidSdk
    android-emulator
  ];

  home.sessionVariables = {
    # Expose JDK without polluting PATH
    JAVA_HOME = "${pkgs.jdk17_headless.home}";

    # Android SDK
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
  };

  home.sessionPath = [
    "${androidHome}/cmdline-tools/latest/bin"
    "${androidHome}/platform-tools"
    "${androidHome}/emulator"
  ];
}
