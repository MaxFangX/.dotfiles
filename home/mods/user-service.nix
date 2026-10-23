# Not a module: a helper that defines one always-on user service, as a
# systemd user service on Linux and a launchd agent on macOS. Returns
# `{ systemd, launchd }` fragments for the caller to place under
# `systemd.user.services.<name>` and `launchd.agents.<name>`.
{ config, lib, pkgs }:
description: exe:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # launchd discards output unless told where to put it.
  logFile = "${config.home.homeDirectory}/Library/Logs/${baseNameOf exe}.log";
in
{
  systemd = lib.mkIf isLinux {
    Install.WantedBy = [ "default.target" ];

    Unit = {
      Description = description;
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = exe;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  launchd = lib.mkIf isDarwin {
    enable = true;
    # Under load launchd starves a Background process so badly that the
    # router took minutes to start, and these services sit on the request
    # path of interactive agents, so they keep the default process type.
    config = {
      ProgramArguments = [ exe ];
      WorkingDirectory = config.home.homeDirectory;
      StandardOutPath = logFile;
      StandardErrorPath = logFile;
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ThrottleInterval = 5;
    };
  };
}
