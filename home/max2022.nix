{
  pkgs,
  lib,
  sources,
  ...
}:
{
  home.username = "fang";
  home.homeDirectory = "/Users/fang";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  home.file = {
    ".zshrc".source = ../zshrc;
    ".common".source = ../common;
    ".bashrc".source = ../bashrc;
    ".gitconfig".source = ../gitconfig;
    ".tmux.conf".source = ../tmux.conf;
    ".config/nvim".source = ../nvim;
    ".ideavimrc".source = ../nvim/init.lua;
    ".cargo/config.toml".source = ../cargo/config.toml;
    ".claude/CLAUDE.md".source = ../claude/CLAUDE.md;
    ".claude/settings.json".source = ../claude/settings.json;
    ".config/karabiner/assets/complex_modifications".source =
      ../karabiner/assets/complex_modifications;
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Application Support/Code/User/settings.json".source =
      ../vscode/settings.json;
    "Library/Application Support/Code/User/keybindings.json".source =
      ../vscode/keybindings.json;
  };

  # Add dotfiles bin to PATH
  home.sessionPath = [ "$HOME/.dotfiles/bin" ];

  # You can also manage environment variables.
  home.sessionVariables = {
    # EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
