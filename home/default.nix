{
  hm,
  pkgs,
  sources,
  omnara,
}:
{
  max2022 = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [ ./max2022.nix ];
    extraSpecialArgs = {
      inherit pkgs sources omnara;
    };
  };

  lexe-dev-hetzner = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [ ./lexe-dev-hetzner.nix ];
    extraSpecialArgs = {
      inherit pkgs sources omnara;
    };
  };
}
