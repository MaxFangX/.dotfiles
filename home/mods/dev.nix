# General dev tooling — LSP, formatters, direnv.
# Not suitable for security-critical machines.
{ pkgs, claude-agent-acp, claude-code, codex-acp, kimi-code, rsync, ... }:
{
  imports = [
    ./core.nix
    ./paseo.nix
  ];

  home.packages = [
    claude-agent-acp # ACP adapter for claude (see pkgs/claude-agent-acp)
    claude-code
    codex-acp # ACP adapter for codex (see pkgs/codex-acp)
    kimi-code # Moonshot AI's `kimi` CLI (see pkgs/kimi-code)
    rsync # Platform-aware wrapper (see pkgs/rsync.nix)
    pkgs.bat # Cat with syntax highlighting
    pkgs.gh # GitHub CLI
    pkgs.go
    pkgs.goose-cli # Block's goose AI agent
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
    GOPATH = "$HOME/gocode";
    AIDER_ARCHITECT = "true";
    AIDER_AUTO_COMMITS = "false";
    AIDER_DARK_MODE = "true";
    AIDER_EDITOR_MODEL = "openrouter/anthropic/claude-3.5-sonnet";
    AIDER_MODEL = "openai/o1";
    AIDER_SHOW_MODEL_WARNINGS = "false";
    DOTFILES_NVIM_ENABLE_COC = "1";
  };

  home.sessionPath = [
    "$HOME/gocode/bin"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
