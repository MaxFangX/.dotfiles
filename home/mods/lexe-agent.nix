# The shared lexe-agent identity. Used as the host-default commit
# author on the agent's own machine (hetzner) and by omnara-driven
# work on personal machines (max2022). Declared once so the two
# can't drift apart.
{ lib, ... }:
{
  options.lexe.agent = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "Lexe Agent";
      description = "Git author/committer name for the lexe-agent.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "noreply@lexe.app";
      description = "Git author/committer email for the lexe-agent.";
    };
  };
}
