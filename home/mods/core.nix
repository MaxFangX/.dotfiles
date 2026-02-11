# Shared config across all machines.
{ pkgs, ... }:
{
  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.just
    pkgs.jq
    pkgs.neovim
    pkgs.rustup
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
    BAT_THEME = "gruvbox-dark";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    defaultCommand = builtins.concatStringsSep " " [
      "rg --files --fixed-strings --ignore-case"
      "--no-ignore --hidden --follow"
      "--glob '!*.git/*' --glob '!*target/*'"
    ];
    defaultOptions = [
      "--bind" "alt-a:select-all"
    ];
  };

  home.sessionPath = [
    "$HOME/.dotfiles/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables.MANPATH =
    "/usr/share/man:$HOME/.local/share/man:$MANPATH";

  home.file = {
    ".zshrc".source = ../../zshrc;
    ".common".source = ../../common;
    ".bashrc".source = ../../bashrc;
    ".gitconfig".source = ../../gitconfig;
    ".tmux.conf".source = ../../tmux.conf;
    ".config/nvim".source = ../../nvim;
    ".cargo/config.toml".source = ../../cargo/config.toml;
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".claude/settings.json".source =
      ../../claude/settings.json;
  };

  programs.home-manager.enable = true;
}
