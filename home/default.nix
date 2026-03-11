{
  hm,
  pkgs,
  sources,
  claude-code,
  codex,
  omnara,
}:
{
  max2022 = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [ ./max2022.nix ];
    extraSpecialArgs = {
      inherit pkgs sources claude-code codex omnara;
    };
  };

  lexe-dev-hetzner = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [ ./lexe-dev-hetzner ];
    extraSpecialArgs = {
      inherit pkgs sources claude-code codex omnara;
    };
  };
}
