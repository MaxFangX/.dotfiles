{
  hm,
  pkgs,
  sources,
}:
{
  max2022 = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [ ./max2022.nix ];
    extraSpecialArgs = {
      inherit pkgs sources;
    };
  };
}
