{
  pkgs,
  sources,
  ...
}:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "fang";
  home.homeDirectory = "/Users/fang";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  # Home Manager can manage your dotfiles. The primary way to manage plain files
  # is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc'
    # # a symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
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
