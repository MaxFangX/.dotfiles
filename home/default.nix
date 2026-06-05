{
  hm,
  pkgs,
  sources,
  claude-code,
  codex,
  git-hunk,
  omnara,
  rsync,
}:
let
  lib = pkgs.lib;

  # Convention: a machine-specific (possibly private) repo cloned to
  # ~/<hostname> extends the public dotfiles config by exposing a
  # home.nix at its root, i.e. ~/<hostname>/home.nix.
  homeDir = builtins.getEnv "HOME";
  machineRoot = /. + homeDir;
  machineModulePath = name: machineRoot + "/${name}/home.nix";
  machineModule = name:
    let path = machineModulePath name;
    in lib.optional (builtins.pathExists path) path;

  # A few prebuilt CLIs ship only for some platforms (see each
  # package's meta.platforms). On an unsupported host — e.g. an
  # aarch64-linux box — substitute an empty stub so the base config
  # still evaluates. The tool just won't be available there; a host
  # that needs it can install its own build in home.packages. Driven
  # by meta.platforms, so a package upgrades from stub to real
  # automatically once its platform is supported.
  stubUnsupported = pkg:
    if lib.meta.availableOn pkgs.stdenv.hostPlatform pkg
    then pkg
    else pkgs.runCommand "${pkg.pname}-stub" {} "mkdir -p $out/bin";

  mkHome = name: modules: hm.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = modules ++ machineModule name;
    extraSpecialArgs = {
      inherit pkgs sources git-hunk rsync;
      claude-code = stubUnsupported claude-code;
      codex = stubUnsupported codex;
      omnara = stubUnsupported omnara;
    };
  };

  # Auto-discover machine configs under ~/<name>/home.nix. Any such
  # directory becomes a homeConfig with no public mention required —
  # useful for private hosts.
  discovered =
    let
      entries =
        if homeDir != "" && builtins.pathExists machineRoot
        then builtins.readDir machineRoot
        else {};
      # A ~/<name> with a home.nix inside is a machine config. No need
      # to check the entry type: pathExists fails on a non-directory.
      hasModule = name: builtins.pathExists (machineModulePath name);
      names = lib.filter hasModule (builtins.attrNames entries);
    in lib.genAttrs names (name: mkHome name []);

  # Explicit hosts whose public module list lives in this repo. These
  # take precedence over auto-discovered entries of the same name.
  explicit = {
    max2022 = mkHome "max2022" [ ./max2022.nix ];

    max-nitropad-2024 =
      mkHome "max-nitropad-2024" [ ./max-nitropad-2024.nix ];

    lexe-dev-hetzner = mkHome "lexe-dev-hetzner" [
      ./lexe-dev-hetzner
    ];

    lexe-dev = mkHome "lexe-dev" [
      ./mods/dev.nix
      {
        home.username = "maxfangx";
        home.homeDirectory = "/home/maxfangx";
        home.stateVersion = "25.05";
      }
    ];
  };
in
discovered // explicit
