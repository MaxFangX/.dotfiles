# lspmux: one rust-analyzer per directory, shared by every Claude Code
# session working there.
#
# Claude Code's official rust-analyzer plugin starts a ~2.5 GB server per
# session and keeps it while the session lives, so core.nix disables it.
# The plugin below launches `lspmux client` instead, which connects the
# session to the `lspmux server` service. The server runs one
# rust-analyzer per session directory and kills it five minutes after its
# last client disconnects.
#
# `lspmux status` lists the running instances and their clients.
{ config, lib, pkgs, ... }:
let
  mkService = import ./user-service.nix { inherit config lib pkgs; };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # The server spawns whatever command a client names, so it listens on a
  # unix socket only this user can reach, not on the default TCP port.
  socketDir = "${config.xdg.stateHome}/lspmux";
  socket = "${socketDir}/lspmux.sock";

  configFile = (pkgs.formats.toml { }).generate "lspmux-config.toml" {
    listen = socket;
    connect = socket;
  };
  # lspmux only reads its config from the platform's config directory.
  configDir =
    if isDarwin
    then "Library/Application Support/lspmux"
    else "${config.xdg.configHome}/lspmux";

  # launchd and systemd start the server with a minimal environment, and
  # the server starts `rust-analyzer` by name in it. So give the server
  # the Home Manager session environment, where the name resolves to
  # bin/rust-analyzer, which picks the toolchain the session directory
  # pins. Its cargo runs then also see the same variables as an agent's,
  # so the two reuse each other's builds.
  profile = config.home.profileDirectory;
  serverStart = pkgs.writeShellScriptBin "lspmux-server" ''
    # Restart the service when the config changes: ${configFile}
    export PATH="${lib.concatStringsSep ":" (
      [ "${profile}/bin" "/nix/var/nix/profiles/default/bin" ]
      ++ lib.optional isDarwin "/opt/homebrew/bin"
    )}:$PATH"
    . "${profile}/etc/profile.d/hm-session-vars.sh"

    mkdir -p -m 700 "${socketDir}"
    exec ${lib.getExe pkgs.lspmux} server
  '';

  server = mkService "lspmux server" (lib.getExe serverStart);

  # Declares the same LSP server as the official plugin, but launches the
  # lspmux client.
  plugin = {
    name = "rust-analyzer-shared";
    description = "rust-analyzer, shared between sessions through lspmux";
    lspServers.rust-analyzer = {
      command = lib.getExe pkgs.lspmux;
      args = [ "client" ];
      extensionToLanguage.".rs" = "rust";
    };
  };
in
{
  home.packages = [ pkgs.lspmux ];

  home.file = {
    "${configDir}/config.toml".source = configFile;
    # Claude Code loads a ~/.claude/skills directory that has a plugin
    # manifest as a plugin, here `rust-analyzer-shared@skills-dir`. It is
    # enabled by default.
    ".claude/skills/rust-analyzer-shared/.claude-plugin/plugin.json".text =
      builtins.toJSON plugin;
  };

  systemd.user.services.lspmux = server.systemd;
  launchd.agents.lspmux = server.launchd;
}
