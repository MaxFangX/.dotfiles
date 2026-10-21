# Paseo. Imported by mods/dev.nix, so every dev machine gets:
#
#  1. The nix-packaged @getpaseo/cli, i.e. `paseo` in PATH.
#
#  2. A `cross-env` shim for local Paseo *development* (only when a
#     checkout exists). Paseo's paseo.json setup/service commands invoke
#     a bare `cross-env`, which normally resolves from the repo's
#     node_modules/.bin. Our nix-managed PATH doesn't include that dir,
#     so those commands die with `command not found: cross-env`. We're on
#     a fork that continually rebases onto upstream, so we fix this in the
#     environment rather than editing the upstream-tracked paseo.json.
#
#  3. The Paseo desktop app from @maxfangx's fork releases
#     (macOS only; a stub elsewhere). Lands in
#     ~/Applications/Home Manager Apps via targets.darwin.copyApps.
#
#  4. Daemon settings (`lexe.paseo.daemonConfig`), applied to
#     ~/.paseo/config.json at activation with `paseo daemon config set`
#     and reloaded live when a daemon is up. The daemon owns that file
#     (the settings UI writes it), so nix can't manage it as a whole;
#     setting individual paths through the CLI keeps both happy.
#     Default: inject Paseo's agent tools into agents, so an agent can
#     spawn and resume Paseo workers instead of Task children.
#
# Plus one opt-in piece:
#
#  5. An always-on Paseo *daemon* (`lexe.paseo.enableService`).
#     Runs `paseo daemon run` from the nix-packaged
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
  paseo-app,
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
    exec ${paseo}/bin/paseo daemon run --home "${homeDir}/.paseo"
  '';
in
{
  options.lexe.paseo.enableService = lib.mkEnableOption ''
    an always-on Paseo daemon (systemd user service / launchd agent)
    using the nix-packaged @getpaseo/cli'';

  options.lexe.paseo.daemonConfig = lib.mkOption {
    type = lib.types.attrsOf (lib.types.oneOf [ lib.types.bool lib.types.int lib.types.str ]);
    default = { };
    description = ''
      Paseo daemon settings by dotted config path (see `paseo daemon
      config get`), applied to ~/.paseo/config.json at activation.
    '';
    example = { "daemon.mcp.injectIntoAgents" = true; };
  };

  config = lib.mkMerge [
    # (1) The CLI, (2) the dev shim when a checkout is present, and
    # (3) the desktop app.
    {
      home.packages = [ paseo paseo-app ]
        ++ lib.optional (builtins.pathExists paseoRepo) crossEnv;
    }

    # (4) Daemon settings. `config set` saves, then reloads the running
    # daemon when there is one, so this is safe with the daemon up or down.
    {
      lexe.paseo.daemonConfig."daemon.mcp.injectIntoAgents" = lib.mkDefault true;

      home.activation.paseoDaemonConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (path: value: ''
          ${paseo}/bin/paseo daemon config set --home "${homeDir}/.paseo" \
            ${lib.escapeShellArg path} ${lib.escapeShellArg (builtins.toJSON value)} \
            >/dev/null || echo "paseo daemon config set ${path} failed" >&2
        '') cfg.daemonConfig)
      );
    }

    # (5) Always-on daemon — opt-in per host.
    (lib.mkIf cfg.enableService {
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
