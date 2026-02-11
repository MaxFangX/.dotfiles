{
  pkgs,
  sources,
  ...
}:
{
  imports = [
    ./mods/omnara.nix
  ];

  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  # Add dotfiles bin to PATH
  home.sessionPath = [ "$HOME/.dotfiles/bin" ];

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
