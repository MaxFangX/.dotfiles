# lexe-dev-hetzner — Linux dev server (Hetzner)
{
  config,
  pkgs,
  sources,
  ...
}:
{
  imports = [
    ../mods/dev-lexe.nix
    ../mods/omnara.nix
    ../mods/paseo.nix
  ];

  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.05";

  # Run an always-on Paseo daemon (relay on → reachable from the app).
  lexe.paseo.enableService = true;

  # Server packages managed via Nix instead of apt.
  home.packages = [
    pkgs.lego
    pkgs.nginx
  ];

  # This machine uses the lexe-agent GitHub account.
  programs.git = {
    settings.user = {
      inherit (config.lexe.agent) name email;
    };
    # Auto-append co-author trailer so Max Fang shows
    # as a contributor on commits from this machine.
    hooks.prepare-commit-msg = ./prepare-commit-msg;
  };
}
