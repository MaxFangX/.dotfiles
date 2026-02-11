# Shared config across all machines.
{ pkgs, ... }:
{
  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  home.sessionPath = [ "$HOME/.dotfiles/bin" ];

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
