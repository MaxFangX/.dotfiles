# Shared config across all machines.
{
  config, lib, pkgs, sources, codex, complain, git-hunk, jj, jj-hunk-tool,
  macctl, ...
}:
let
  # Agent skills in ai/skills/. Some are vendored copies: skills written by me
  # but managed in the lexe repo, and Paseo's own agent skills from the fork
  # checkout. Keep them in sync with `just skills-diff <peer>` /
  # `just skills-sync <peer> from|to` (see just/skill-sync.sh).
  sharedSkillNames = [
    "codex-review"
    "complain"
    "jj"
    "jj-cleanup"
    "jj-rebase"
    "knowledge-doc"
    "lexe-way"
    "macctl"
    "orchestrate"
    "paseo"
    "paseo-handoff"
    "paseo-orchestrate"
    "q"
    "rebase-review"
    "temp-worktree"
    "tighten"
    "tighten-code"
    "tighten-comments"
  ];
  sharedSkillFiles = lib.listToAttrs (lib.concatMap (name: [
    {
      name = ".claude/skills/${name}";
      value.source = ../../ai/skills + "/${name}";
    }
    {
      name = ".codex/skills/${name}";
      value.source = ../../ai/skills + "/${name}";
    }
  ]) sharedSkillNames);

  # Third-party skill, pinned with npins rather than vendored.
  securityAuditSkill =
    "${sources.security-audit-skill}/skills/security-audit";
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
    pkgs.visidata # Terminal CSV/TSV viewer (`vd file.tsv`)
    pkgs.zsh
    codex
    complain
    git-hunk
    jj-hunk-tool
    macctl

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
    ".claude/skills/git-hunk/SKILL.md".source =
      "${git-hunk}/share/git-hunk/SKILL.md";
    ".codex/skills/git-hunk/SKILL.md".source =
      "${git-hunk}/share/git-hunk/SKILL.md";
    ".claude/skills/security-audit".source = securityAuditSkill;
    ".codex/skills/security-audit".source = securityAuditSkill;
    # TODO(max): Let Claude Code manage settings.json itself for now, since
    # the home-manager symlink into /nix/store is read-only, which breaks
    # `/effort` and other commands that write to settings.json.
    # ".claude/settings.json".source =
    #   ../../claude/settings.json;
  } // sharedSkillFiles;

  programs.home-manager.enable = true;

  # Ensure ~/env/sensitive.sh is always 600 (read/write only by the owner).
  home.activation.sensitiveEnvPerms =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "$HOME/env/sensitive.sh" ]; then
        run chmod 600 "$HOME/env/sensitive.sh"
      fi
    '';

  # Restore lazy.nvim plugins to the tracked nvim/lazy-lock.json so every
  # host runs the same commits. lazy works from a per-host copy of the
  # lockfile (see nvim/lua/config/lazy.lua), which we seed from the tracked
  # file. `install` only honors the lockfile when asked and skips plugins
  # already installed, so `restore` then moves those. lazy logs every task
  # and exits 0 even when one fails, so LAZY_QUIET silences its logging and
  # the script reports only errored tasks. Needs network, so failures warn
  # rather than fail the switch.
  home.activation.lazyNvimRestore =
    let
      restore = pkgs.writeText "lazy-restore.lua" ''
        local lazy = require("lazy")
        local Config = require("lazy.core.config")

        lazy.install({ wait = true, lockfile = true, show = false })
        lazy.restore({ wait = true, show = false })

        local failed = {}
        for _, plugin in pairs(Config.plugins) do
          for _, task in ipairs(plugin._.tasks or {}) do
            if task:has_errors() then
              table.insert(failed, ("[%s] %s: %s"):format(
                plugin.name, task.name, task:output(vim.log.levels.ERROR)))
            end
          end
        end
        if #failed > 0 then
          io.stderr:write(table.concat(failed, "\n") .. "\n")
          vim.cmd("cquit 1")
        end
        vim.cmd("qall")
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      lazyLock="${config.xdg.stateHome}/nvim/lazy/lazy-lock.json"
      run mkdir -p "$(dirname "$lazyLock")"
      run cp ${../../nvim/lazy-lock.json} "$lazyLock"
      run chmod 644 "$lazyLock"
      run env LAZY_QUIET=1 ${pkgs.neovim}/bin/nvim \
        --headless "+luafile ${restore}" \
        || echo "lazy.nvim restore failed; run :Lazy restore in nvim" >&2
    '';

  # Skip building the `man home-configuration.nix` page. We never
  # use it, and its generation emits a noisy "options.json without
  # proper context" warning on every activation.
  manual.manpages.enable = false;
}
