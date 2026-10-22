# lexe-dev-hetzner — Linux dev server (Hetzner)
{
  config,
  pkgs,
  sources,
  ...
}:
{
  imports = [
    ../mods/agent-browser.nix # Browser for agents testing web apps
    ../mods/dev-lexe.nix
    ../mods/omnara.nix
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

  # Server packages managed via Nix instead of apt.
  home.packages = [
    pkgs.lego
    pkgs.nginx
  ];

  # This machine uses the lexe-agent GitHub account.
  programs.git = {
    settings.user = {
      inherit (config.lexe.agent) name email;
    };
    # Auto-append co-author trailer so Max Fang shows
    # as a contributor on commits from this machine.
    hooks.prepare-commit-msg = ./prepare-commit-msg;
  };
}
