# Zen Browser prefs, written to each profile's user.js, which Zen applies
# over its own prefs on every start.
{ lib, ... }:
let
  profiles = [ "Lexe" "Personal" ];

  prefs = {
    # On macOS, Zen (like Firefox release, unlike Nightly) ignores memory
    # pressure. 3 = unload the least recently used tabs and have Zen free
    # memory (caches, GC), as AvailableMemoryWatcherMac.cpp describes.
    "browser.lowMemoryResponseMask" = 3;
    # Respond at macOS's "warning" pressure level, before "critical"
    "browser.lowMemoryResponseOnWarn" = true;
  };

  userJs = lib.concatStrings (lib.mapAttrsToList
    (name: value:
      "user_pref(${builtins.toJSON name}, ${builtins.toJSON value});\n")
    prefs);
in
{
  home.file = lib.listToAttrs (map
    (profile: {
      name = "Library/Application Support/zen/Profiles/${profile}/user.js";
      # Replace any user.js written outside home-manager
      value = { text = userJs; force = true; };
    })
    profiles);
}
