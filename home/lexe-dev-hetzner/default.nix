# lexe-dev-hetzner — Linux dev server (Hetzner)
{
  pkgs,
  sources,
  ...
}:
{
  imports = [
    ../mods/dev-lexe.nix
    ../mods/omnara.nix
  ];

  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.05";

  # Server packages managed via Nix instead of apt.
  home.packages = [
    pkgs.lego
    pkgs.nginx
  ];

  # This machine uses the lexe-agent GitHub account.
  programs.git = {
    userName = "Lexe Agent";
    userEmail = "noreply@lexe.app";
    # Auto-append co-author trailer so Max Fang shows
    # as a contributor on commits from this machine.
    hooks.prepare-commit-msg =
      ./prepare-commit-msg;
  };
}
