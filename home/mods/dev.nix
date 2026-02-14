# General dev tooling — LSP, formatters, direnv.
# Not suitable for security-critical machines.
{ pkgs, claude-code, ... }:
{
  imports = [
    ./core.nix
  ];

  home.packages = [
    claude-code
    pkgs.nodejs # Required by coc.nvim
    pkgs.nil # Nix LSP
    pkgs.nixfmt-rfc-style # Nix formatter
  ];

  home.sessionVariables = {
    AIDER_ARCHITECT = "true";
    AIDER_AUTO_COMMITS = "false";
    AIDER_DARK_MODE = "true";
    AIDER_EDITOR_MODEL =
      "openrouter/anthropic/claude-3.5-sonnet";
    AIDER_MODEL = "openai/o1";
    AIDER_SHOW_MODEL_WARNINGS = "false";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
