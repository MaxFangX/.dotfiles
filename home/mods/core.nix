# Shared config across all machines.
{ config, lib, pkgs, sources, codex, git-hunk, jj, jj-hunk-tool, ... }:
let
  # The lexe repo always lives at one of these paths. Resolve the
  # first that exists so we can symlink in slash commands it owns.
  # Null on machines without the repo, in which case those symlinks
  # are omitted.
  homeDir = config.home.homeDirectory;
  lexeRepo = lib.findFirst builtins.pathExists null [
    "${homeDir}/lexe/org/lexe"
    "${homeDir}/dev/lexe"
    "${homeDir}/lexe"
    "${homeDir}/lexe-agent/lexe"
  ];

  # Claude slash commands owned by the lexe repo. Symlinked to its
  # live working tree so edits there take effect without a rebuild.
  lexeCommands = [
    "tighten"
    "tighten-code"
    "tighten-comments"
    "codex-review"
  ];
  lexeCommandFiles = lib.optionalAttrs (lexeRepo != null) (
    lib.listToAttrs (map (name: {
      name = ".claude/commands/${name}.md";
      value.source = config.lib.file.mkOutOfStoreSymlink
        "${lexeRepo}/.claude/commands/${name}.md";
    }) lexeCommands)
  );
in
{
  imports = [
    ./git.nix
    ./jj.nix
    # Shared lexe.agent identity option, available on all machines
    # (consumed by the hetzner host default and omnara routing).
    ./lexe-agent.nix
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
    git-hunk
    jj-hunk-tool

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
    # Global justfile: machine-wide recipes via `just -g <recipe>`. just resolves
    # `mod` paths relative to the deployed justfile, so link the just/ tree next
    # to it so the worktree/workspace modules (and their scripts) resolve.
    ".config/just/justfile".source = ../../global.justfile;
    ".config/just/just".source = ../../just;
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
    # Slash commands owned by this repo (vs. lexeCommandFiles below,
    # which symlink to the lexe repo's working tree).
    ".claude/commands/queue-mode.md".source =
      ../../claude/commands/queue-mode.md;
    ".claude/commands/rebase-review.md".source =
      ../../claude/commands/rebase-review.md;
    ".claude/commands/jj-coedit.md".source =
      ../../claude/commands/jj-coedit.md;
    ".claude/commands/temp-worktree.md".source =
      ../../claude/commands/temp-worktree.md;
    ".claude/skills/git-hunk/SKILL.md".source =
      "${git-hunk}/share/git-hunk/SKILL.md";
    ".claude/skills/jj-surgery/SKILL.md".source =
      ../../claude/skills/jj-surgery/SKILL.md;
    ".codex/skills/git-hunk/SKILL.md".source =
      "${git-hunk}/share/git-hunk/SKILL.md";
    # TODO(max): Let Claude Code manage settings.json itself for now, since
    # the home-manager symlink into /nix/store is read-only, which breaks
    # `/effort` and other commands that write to settings.json.
    # ".claude/settings.json".source =
    #   ../../claude/settings.json;
  } // lexeCommandFiles;

  programs.home-manager.enable = true;

  # Skip building the `man home-configuration.nix` page. We never
  # use it, and its generation emits a noisy "options.json without
  # proper context" warning on every activation.
  manual.manpages.enable = false;
}
