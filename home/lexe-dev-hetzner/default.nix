# lexe-dev-hetzner — Linux dev server (Hetzner)
{ ... }:
{
  imports = [
    ../mods/agent-browser.nix # Browser for agents testing web apps
    ../mods/dev-lexe.nix
  ];

  # No display here, so agents each get a private headless browser.
  # Ubuntu's AppArmor blocks the user namespaces Chromium's sandbox needs,
  # so /etc/apparmor.d/nix-chromium (hand-installed, like Ubuntu's own
  # chrome profile) grants `userns` to /nix/store/*-playwright-chromium.
  agent-browser.headless = true;

  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "25.05";

  # Run an always-on Paseo daemon (relay on → reachable from the app).
  lexe.paseo.enableService = true;

  # This machine uses the lexe-agent GitHub account.
  programs.git = {
    settings.user = {
      name = "Lexe Agent";
      email = "noreply@lexe.app";
    };
    # Auto-append co-author trailer so Max Fang shows
    # as a contributor on commits from this machine.
    hooks.prepare-commit-msg = ./prepare-commit-msg;
  };

  # jj skips git hooks, so it adds the same trailer itself.
  programs.jujutsu.settings.templates.commit_trailers =
    ''"Co-authored-by: Max Fang <hello@maxfa.ng>"'';
}
