# Paseo — two independent pieces:
#
#  1. A `cross-env` shim for local Paseo *development* (always on when a
#     checkout exists). Paseo's paseo.json setup/service commands invoke
#     a bare `cross-env`, which normally resolves from the repo's
#     node_modules/.bin. Our nix-managed PATH doesn't include that dir,
#     so those commands die with `command not found: cross-env`. We're on
#     a fork that continually rebases onto upstream, so we fix this in the
#     environment rather than editing the upstream-tracked paseo.json.
#
#  2. An opt-in always-on Paseo *daemon* (`lexe.paseo.enableService`).
#     Runs `paseo daemon start --foreground` from the nix-packaged
#     @getpaseo/cli as a systemd user service (Linux) or launchd agent
#     (macOS), modeled on home/mods/omnara.nix. Relay stays on by default
#     so the daemon is reachable from the phone/desktop app; pair it with
#     `paseo daemon pair`. Off by default so importing this module on a
#     dev laptop doesn't spin up a production daemon.
{
  config,
  lib,
  pkgs,
  paseo,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  homeDir = config.home.homeDirectory;
  paseoRepo = "${homeDir}/dev/paseo";
  envFile = "${homeDir}/env/sensitive.sh";

  cfg = config.lexe.paseo;

  crossEnv = pkgs.writeShellScriptBin "cross-env" ''
    # Delegate to the Paseo checkout's real cross-env. Prefer the repo
    # of the current working dir (e.g. a worktree under ~/.paseo) when
    # it has one, then fall back to the canonical checkout in ~/dev.
    for bin in \
      "$PWD/node_modules/.bin/cross-env" \
      "${paseoRepo}/node_modules/.bin/cross-env"; do
      if [ -x "$bin" ]; then
        exec "$bin" "$@"
      fi
    done
    echo "cross-env shim: no cross-env found in $PWD or ${paseoRepo}" >&2
    exit 127
  '';

  # The daemon launches agent CLIs (claude, codex, git, node, ...), so it
  # needs the same nix-managed PATH an interactive shell gets. systemd /
  # launchd start with a bare environment, so source home-manager's
  # session vars and prepend the profile bin before exec'ing the daemon.
  startScript = pkgs.writeShellScript "paseo-start" ''
    sessionVars="${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    [ -f "$sessionVars" ] && . "$sessionVars"
    [ -f "${envFile}" ] && . "${envFile}"
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    exec ${paseo}/bin/paseo daemon start --foreground
  '';
in
{
  options.lexe.paseo.enableService = lib.mkEnableOption ''
    an always-on Paseo daemon (systemd user service / launchd agent)
    using the nix-packaged @getpaseo/cli'';

  config = lib.mkMerge [
    # (1) Dev shim — only when a Paseo checkout is present.
    {
      home.packages = lib.optional (builtins.pathExists paseoRepo) crossEnv;
    }

    # (2) Always-on daemon — opt-in per host.
    (lib.mkIf cfg.enableService {
      home.packages = [ paseo ];

      # Enable "linger" so the systemd user instance (and thus this
      # service) starts at boot, not just on login.
      home.activation.enablePaseoLinger = lib.mkIf isLinux (
        lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
          ${pkgs.systemd}/bin/loginctl enable-linger \
            --no-ask-password "$USER" 2>/dev/null || true
        ''
      );

      # Linux — systemd user service
      systemd.user.services.paseo = lib.mkIf isLinux {
        Install.WantedBy = [ "default.target" ];

        Unit = {
          Description = "Paseo Daemon";
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

      # macOS — launchd agent
      launchd.agents.paseo = lib.mkIf isDarwin {
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
    })
  ];
}
