# Run Omnara as a background daemon service.
#
# The daemon self-updates to ~/.omnara/bin/omnara. We prefer
# that binary and fall back to the nix-managed one on first
# boot or after `hms`.
{
  config,
  lib,
  omnara,
  pkgs,
  ...
}:
let
  isLinux = pkgs.hostPlatform.isLinux;
  isDarwin = pkgs.hostPlatform.isDarwin;

  homeDir = config.home.homeDirectory;

  # Prefer self-updated binary; fall back to nix-managed.
  selfUpdated = "${homeDir}/.omnara/bin/omnara";
  fallback = "${omnara}/bin/omnara";
  startScript = pkgs.writeShellScript "omnara-start" ''
    BIN=${selfUpdated}
    [ -x "$BIN" ] || BIN=${fallback}
    exec "$BIN" daemon run-service
  '';
in
{
  home.packages = [ omnara ];

  # Prefer the self-updated binary over the nix-managed one.
  home.sessionPath = [ "$HOME/.omnara/bin" ];

  # Enable "linger" so the systemd user instance (and thus
  # this service) starts at boot, not just on login.
  home.activation.enableLinger = lib.mkIf isLinux (
    lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      ${pkgs.systemd}/bin/loginctl enable-linger "$USER" \
        2>/dev/null || true
    ''
  );

  # Linux - systemd user service
  systemd.user.services.omnara = lib.mkIf isLinux {
    Install.WantedBy = [ "default.target" ];

    Unit = {
      Description = "Omnara Background Daemon";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = toString startScript;
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = homeDir;
    };
  };

  # macOS - launchd agent
  launchd.agents.omnara = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProcessType = "Background";
      ProgramArguments = [ (toString startScript) ];
      WorkingDirectory = homeDir;
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ThrottleInterval = 5;
    };
  };
}
