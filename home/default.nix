{
  hm,
  pkgs,
  sources,
  claude-code,
  codex,
  omnara,
  rsync,
}:
let
  lib = pkgs.lib;

  # Convention: if ~/<hostname>/home.nix exists, import it as an
  # extra home-manager module. This allows machine-specific repos
  # (which may be private) to extend the public dotfiles config.
  machineModule = name:
    let path = /home/dev + "/${name}/home.nix";
    in lib.optional (builtins.pathExists path) path;

  mkHome = name: modules: hm.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = modules ++ machineModule name;
    extraSpecialArgs = {
      inherit pkgs sources claude-code codex omnara rsync;
    };
  };
in
{
  max2022 = mkHome "max2022" [ ./max2022.nix ];

  max-nitropad-2024 =
    mkHome "max-nitropad-2024" [ ./max-nitropad-2024.nix ];

  lexe-dev-hetzner = mkHome "lexe-dev-hetzner" [
    ./lexe-dev-hetzner
  ];
}
