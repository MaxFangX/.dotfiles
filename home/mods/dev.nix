# Dev tooling — heavier dependencies for development machines.
# Not suitable for security-critical machines.
{ pkgs, ... }:
{
  home.packages = [
    pkgs.nil # Nix LSP
    pkgs.nixfmt-rfc-style # Nix formatter
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
