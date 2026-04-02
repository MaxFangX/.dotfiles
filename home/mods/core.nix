# Shared config across all machines.
{ pkgs, codex, ... }:
{
  imports = [
    ./git.nix
  ];

  home.packages = [
    pkgs.delta
    pkgs.htop
    pkgs.ripgrep
    pkgs.fd
    pkgs.just
    pkgs.jq
    pkgs.neovim
    pkgs.rustup
    codex

    # Installed as a package so it's always in PATH,
    # even when hm-session-vars.sh is skipped.
    (pkgs.writeShellScriptBin "hms"
      (builtins.readFile ../../bin/hms))
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
    BAT_THEME = "gruvbox-dark";
  };

  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;
    enableCompletion = true;
    initExtra = builtins.readFile ../../shell/bashrc-interactive.sh;
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
    ".tmux.conf".source = ../../tmux.conf;
    ".config/nvim".source = ../../nvim;
    ".cargo/config.toml".source = ../../cargo/config.toml;
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".claude/settings.json".source =
      ../../claude/settings.json;
  };

  programs.home-manager.enable = true;
}
