{
  pkgs,
  sources,
  ...
}:
{
  imports = [
    ./mods/core.nix
    ./mods/omnara.nix
  ];

  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.05";
}
