# General dev tooling — LSP, formatters, direnv.
# Not suitable for security-critical machines.
{ pkgs, claude-code, rsync, ... }:
{
  imports = [
    ./core.nix
  ];

  home.packages = [
    claude-code
    rsync # Platform-aware wrapper (see pkgs/rsync.nix)
    # pkgs.bat # Cat with syntax highlighting
    pkgs.gh # GitHub CLI
    pkgs.go
    pkgs.nil # Nix LSP
    pkgs.nixfmt-rfc-style # Nix formatter
    pkgs.nodejs # Required by coc.nvim
    pkgs.python3
    pkgs.tmux
    pkgs.tree
    pkgs.uv # Python package manager
    pkgs.wget
    pkgs.yubikey-manager # ykman CLI
  ];

  home.sessionVariables = {
    AIDER_ARCHITECT = "true";
    AIDER_AUTO_COMMITS = "false";
    AIDER_DARK_MODE = "true";
    AIDER_EDITOR_MODEL = "openrouter/anthropic/claude-3.5-sonnet";
    AIDER_MODEL = "openai/o1";
    AIDER_SHOW_MODEL_WARNINGS = "false";
    DOTFILES_NVIM_ENABLE_COC = "1";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
