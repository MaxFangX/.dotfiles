# Shared jujutsu (jj) config across all machines.
{ config, jj, ... }:
{
  programs.jujutsu = {
    enable = true;
    package = jj;

    settings = {
      # Reuse the git identity so the two stay in sync. Machine
      # configs override it there (git.nix uses mkDefault).
      user = {
        inherit (config.programs.git.settings.user) name email;
      };

      # Render commit IDs as their shortest unique prefix.
      template-aliases."format_short_id(id)" = "id.shortest()";

      # Page in the alternate screen so scrollback stays clean on quit.
      # Same as jj's default `less -FRX`, minus the `-X` that suppresses it.
      ui.pager = {
        command = [ "less" "-FR" ];
        env.LESSCHARSET = "utf-8";
      };
    };
  };
}
