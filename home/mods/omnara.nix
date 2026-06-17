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
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  homeDir = config.home.homeDirectory;

  # Prefer self-updated binary; fall back to nix-managed.
  selfUpdated = "${homeDir}/.omnara/bin/omnara";
  fallback = "${omnara}/bin/omnara";
  envFile = "${homeDir}/env/sensitive.sh";

  # On machines where the host default is Max's personal identity
  # (e.g. max2022), route everything omnara does — commit
  # author/committer, SSH push key, and gh account — through the
  # lexe-agent instead. Off by default; machines whose host default
  # is already lexe-agent (hetzner) or always Max (others) don't set
  # it. Enabling it requires a one-time `gh auth login` into
  # `ghConfigDir`.
  agent = config.lexe.agent;
  agentSshKey = "${homeDir}/.ssh/lexe-agent-ed25519-2026_03_16";
  ghConfigDir = "${homeDir}/.config/gh-lexe-agent";
  agentEnv = ''
    export GIT_AUTHOR_NAME="${agent.name}"
    export GIT_AUTHOR_EMAIL="${agent.email}"
    export GIT_COMMITTER_NAME="${agent.name}"
    export GIT_COMMITTER_EMAIL="${agent.email}"
    # -F /dev/null ignores ~/.ssh/config, whose `Host *` IdentityFile
    # (and the agent) would otherwise also offer Max's personal key —
    # which `IdentitiesOnly` does not suppress — and authenticate as Max.
    export GIT_SSH_COMMAND="ssh -F /dev/null -i ${agentSshKey} -o IdentitiesOnly=yes"
    export GH_CONFIG_DIR="${ghConfigDir}"
  '';

  startScript = pkgs.writeShellScript "omnara-start" ''
    [ -f ${envFile} ] && . ${envFile}
    ${lib.optionalString config.lexe.omnara.useAgentIdentity agentEnv}
    BIN=${selfUpdated}
    [ -x "$BIN" ] || BIN=${fallback}
    exec "$BIN" daemon run-service
  '';
in
{
  options.lexe.omnara.useAgentIdentity = lib.mkEnableOption ''
    routing omnara-spawned git/ssh/gh through the lexe-agent
    identity instead of the host default'';

  config = {
    home.packages = [ omnara ];

    # Enable "linger" so the systemd user instance (and thus
    # this service) starts at boot, not just on login.
    home.activation.enableLinger = lib.mkIf isLinux (
      lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
        ${pkgs.systemd}/bin/loginctl enable-linger \
          --no-ask-password "$USER" 2>/dev/null || true
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
  };
}
