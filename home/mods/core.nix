# Shared config across all machines.
{ lib, pkgs, sources, codex, ... }:
{
  imports = [
    ./git.nix
  ];

  home.packages = [
    pkgs.coreutils # GNU coreutils (shadows BSD versions on macOS)
    pkgs.delta
    pkgs.fd
    pkgs.gnumake # Required by telescope-fzf-native.nvim
    pkgs.gnused # GNU sed (shadows BSD sed)
    pkgs.htop
    pkgs.jq
    pkgs.just
    pkgs.neovim
    pkgs.ripgrep
    pkgs.rustup
    pkgs.zsh
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
    HOMEBREW_AUTO_UPDATE_SECS = "604800"; # 1 week
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
    ".dotfiles/zsh/plugins/fzf-tab".source = sources.fzf-tab;
    ".cargo/config.toml".text = lib.concatStrings [
      ''
        # Include links to definitions when viewing source in generated docs
        # rustdocflags = ["-Z", "unstable-options", "--generate-link-to-definition"]
      ''
      (lib.optionalString pkgs.stdenv.isDarwin ''

        # SGX cross-compilation (requires materializeinc/crosstools)
        [target.x86_64-fortanix-unknown-sgx]
        linker = "x86_64-unknown-linux-gnu-ld"
        # runner = "ftxsgx-runner-cargo"

        [env]
        CC_x86_64-fortanix-unknown-sgx = "x86_64-unknown-linux-gnu-gcc"
        AR_x86_64-fortanix-unknown-sgx = "x86_64-unknown-linux-gnu-ar"
      '')
    ];
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    # TODO(max): Let Claude Code manage settings.json itself for now, since
    # the home-manager symlink into /nix/store is read-only, which breaks
    # `/effort` and other commands that write to settings.json.
    # ".claude/settings.json".source =
    #   ../../claude/settings.json;
  };

  programs.home-manager.enable = true;
}
