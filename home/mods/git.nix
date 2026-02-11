# Shared git config across all machines.
{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;

    userName = lib.mkDefault "Max Fang";
    userEmail = lib.mkDefault "hello@maxfa.ng";

    extraConfig = {
      user.signingkey = "98F08E41D2257775";

      credential.helper = "cache --timeout=3600";

      core.editor = "nvim";
      core.pager = "delta";

      init.defaultBranch = "master";

      push.autoSetupRemote = true;
      push.default = "upstream";

      commit.gpgsign = false;

      # --- Delta pager --- #

      interactive.diffFilter = "delta --color-only";

      merge.conflictstyle = "diff3";

      diff.colorMoved = "default";

      delta = {
        navigate = true;
        paging = "always";
        tabs = 4;
        features = "";

        # - gruvmax-fang -
        dark = true;
        syntax-theme = "gruvbox-dark";

        # File
        file-style = ''"#FFFFFF" bold'';
        file-added-label = "(+)";
        file-copied-label = "(==)";
        file-modified-label = "(*)";
        file-removed-label = "(-)";
        file-renamed-label = "(->)";
        file-decoration-style = ''"#84786A" ul'';

        hunk-header-style = "omit";

        # Line numbers
        line-numbers = true;
        line-numbers-left-style = "#84786A";
        line-numbers-right-style = "#84786A";
        line-numbers-minus-style = "#A02A11";
        line-numbers-plus-style = "#479B36";
        line-numbers-zero-style = "#84786A";
        line-numbers-left-format = " {nm:>3} │";
        line-numbers-right-format = " {np:>3} │";

        # Diff contents
        inline-hint-style = "syntax";
        minus-style = ''syntax "#330011"'';
        minus-emph-style = ''syntax "#80002a"'';
        minus-non-emph-style = "syntax auto";
        plus-style = ''syntax "#001a00"'';
        plus-emph-style = ''syntax "#003300"'';
        plus-non-emph-style = "syntax auto";
        whitespace-error-style = ''"#FB4934" reverse'';

        # Commit hash
        commit-decoration-style = "normal box";
        commit-style = ''"#ffffff" bold'';

        # Blame
        blame-code-style = "syntax";
        blame-format =
          "{author:>18} ({commit:>8}) {timestamp:<13}";
        blame-palette =
          ''"#000000" "#1d2021" "#282828" "#3c3836"'';

        # Merge conflicts
        merge-conflict-begin-symbol = "⌃";
        merge-conflict-end-symbol = "⌄";
        merge-conflict-ours-diff-header-style =
          ''"#FABD2F" bold'';
        merge-conflict-theirs-diff-header-style =
          ''"#FABD2F" bold overline'';
        merge-conflict-ours-diff-header-decoration-style =
          "";
        merge-conflict-theirs-diff-header-decoration-style =
          "";
      };

      # Git LFS
      "filter \"lfs\"" = {
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
        clean = "git-lfs clean -- %f";
      };
    };
  };
}
