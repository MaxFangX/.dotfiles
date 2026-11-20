# max2022 — macOS dev machine
{
  pkgs,
  lib,
  sources,
  buzz,
  wdk-cli,
  ...
}:
{
  imports = [
    ./mods/agent-browser.nix # CDP-driven Brave for agent web research
    ./mods/claude-mcp.nix # MCP sync; servers live in ~/max2022
    ./mods/dev-lexe.nix
    ./mods/zen.nix # Zen Browser prefs (user.js)
  ];

  home.packages = [
    buzz # Buzz.app + `buzz-desktop` (see pkgs/buzz)
    wdk-cli # Tether WDK agent wallet; bring-up lives in ~/max2022 (wdk-up)
  ];

  # Copy .app bundles into ~/Applications/Home Manager Apps instead of
  # symlinking them; Spotlight doesn't index symlinked apps.
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  # macOS rewrites a quick double-space as ". " (System Settings >
  # Keyboard > Input Sources > Edit > "Add period with double-space").
  # That injects a stray `.` into nvim's <Space><Space> leader chord,
  # where normal-mode `.` silently repeats the last change. Disabled for
  # iTerm2 only, so the substitution still works in prose apps.
  targets.darwin.defaults."com.googlecode.iterm2" = {
    NSAutomaticPeriodSubstitutionEnabled = false;
    # Background tabs get an unread-style dot on any output at all.
    ShowNewOutputIndicator = false;
  };

  homebrew.casks = [
    "halloy"
    "orbstack"
    "qlcolorcode"
    "qlimagesize"
    "qlmarkdown"
    "qlstephen"
    "quicklook-video"
    "quicklook-json"
    "quicklookase"
    "rar"
    "tad" # Quick Look can't render tables, so a GUI CSV/TSV viewer
  ];

  # Keep Claude Code transcripts three years on this machine, and none
  # from confidential sessions; other hosts get Claude Code's 30-day
  # default for both.
  claude.settings.cleanupPeriodDays = 1095;
  confidential.inMemorySessions = true;

  # Agents build in parallel, and each cargo otherwise runs a job per core,
  # which on 32 GB pushes the Mac deep into swap. Cap each at 4.
  claude.settings.env.CARGO_BUILD_JOBS = "4";

  # Agents commit to lexe-projects as the lexe-agent GitHub account, with
  # Max as co-author, as on lexe-dev-hetzner. jj matches the main repo's
  # path even from its workspaces under ~/lexe/worktrees/ai/.
  programs.jujutsu.settings."--scope" = [
    {
      "--when".repositories = [ "~/lexe/org/lexe-projects" ];
      user = {
        name = "Lexe Agent";
        email = "noreply@lexe.app";
      };
      templates.commit_trailers =
        ''"Co-authored-by: Max Fang <hello@maxfa.ng>"'';
    }
  ];
  # The same for plain `git commit`: in the main repo and its linked
  # worktrees, whose git dirs live in .git/worktrees/ (gitdir), and in
  # any other clone of it, by its remote.
  programs.git.includes =
    map
      (condition: {
        inherit condition;
        contents = {
          user = {
            name = "Lexe Agent";
            email = "noreply@lexe.app";
          };
          core.hooksPath = toString (pkgs.linkFarm "lexe-projects-git-hooks" {
            prepare-commit-msg = ./lexe-dev-hetzner/prepare-commit-msg;
          });
        };
      })
      [
        "gitdir:~/lexe/org/lexe-projects/"
        "hasconfig:remote.*.url:git@github.com:lexe-app/lexe-projects.git"
      ];

  home.username = "fang";
  home.homeDirectory = "/Users/fang";
  home.stateVersion = "25.05";

  home.file = {
    ".ideavimrc".source = ../nvim/init.lua;
    ".config/karabiner/assets/complex_modifications"
      .source =
      ../karabiner/assets/complex_modifications;
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Application Support/iTerm2/DynamicProfiles/maxfangx.json"
      .source = ../iterm2-profile-maxfangx.json;
  };
}
