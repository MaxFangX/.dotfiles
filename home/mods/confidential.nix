# Confidential inference for Claude Code: DeepSeek V4.1 Flash, served
# inside hardware enclaves by Tinfoil (tinfoil.nix) and Maple
# (maple.nix), each behind a local attestation-verifying proxy. Tinfoil
# is the default route at half of Maple's price; Maple also carries
# models Tinfoil does not. Both proxies speak only OpenAI Chat
# Completions, so three pieces sit between Claude Code and them:
#
#  1. claude-code-router on 127.0.0.1:3456 translates Claude Code's
#     Anthropic Messages API, with one upstream per proxy. Keys are
#     expanded from the env at start, and clients authenticate to the
#     router with the Tinfoil key. Requests go to the default route
#     unless the model is named in the router's `provider,model` form:
#
#       ANTHROPIC_MODEL=maple,deepseek-v4-1-flash
#
#     Claude Code warns `unrecognized_model` for such names and would
#     assume a 200K context, so the wrapper pins the window to 1M.
#     The `openrouter` transformer closes thinking blocks early, so no
#     transformer is configured.
#
#  2. `claude-confidential` wraps `claude` for that router. It sets the
#     base URL and token and turns off nonessential traffic (telemetry,
#     error reports, update checks, plugin marketplace fetches), so the
#     proxy is the session's only outbound connection. Transcripts hold
#     full prompt/response bodies, so session state goes to a private
#     state dir apart from ~/.claude, or to RAM with `inMemorySessions`.
#     Enclave tokens cost several times commodity hosting and the global
#     MCP set adds ~56K tokens of tool schemas to every turn, so MCP is
#     restricted to `claude-mcp.confidentialServers`, picked out of
#     ~/.claude.json by name at activation.
#     `--strict-mcp-config` drops project `.mcp.json` servers but keeps
#     `--mcp-config` ones, so Paseo's own MCP injection still applies.
#
#  3. Paseo can't expand env vars in provider config, so
#     confidential-sync.sh writes a `claude-confidential` provider that
#     extends `claude` with the wrapper as its command and the literal
#     key in its env, with one model entry per route.
#
# Keys live in ~/env/sensitive.sh as TINFOIL_API_KEY and MAPLE_API_KEY,
# per machine and never in this repo. Everything here needs the Tinfoil
# key and idles without it; the Maple routes additionally need theirs.
#
# Codex is out. It sends `developer`-role messages, which Tinfoil's
# Responses API rejects, and Maple has no Responses API at all.
{
  config,
  lib,
  pkgs,
  claude-code,
  claude-code-router,
  paseo,
  ...
}:
let
  cfg = config.confidential;
  mkService = import ./user-service.nix { inherit config lib pkgs; };

  envFile = "${config.home.homeDirectory}/env/sensitive.sh";
  routerPort = 3456;
  stateDir = "${config.home.homeDirectory}/.local/state/claude-confidential";

  routerConfig = {
    LOG = false;
    HOST = "127.0.0.1";
    PORT = routerPort;
    APIKEY = "$TINFOIL_API_KEY";
    Providers = [
      {
        name = "tinfoil";
        api_base_url = "http://127.0.0.1:3301/v1/chat/completions";
        api_key = "$TINFOIL_API_KEY";
        models = [ "deepseek-v4-1-flash" ];
      }
      {
        name = "maple";
        api_base_url = "http://127.0.0.1:3302/v1/chat/completions";
        api_key = "$MAPLE_API_KEY";
        models = [
          "deepseek-v4-1-flash"
          "deepseek-v4-1-flash-1017-uncensored"
        ];
      }
    ];
    Router.default = "tinfoil,deepseek-v4-1-flash";
  };

  # Without the Tinfoil key the router would serve unauthenticated, so
  # idle instead.
  routerStart = pkgs.writeShellApplication {
    name = "claude-code-router-start";
    runtimeInputs = [ claude-code-router ];
    text = ''
      # shellcheck disable=SC1091
      [ -f "${envFile}" ] && . "${envFile}"
      if [ -z "''${TINFOIL_API_KEY:-}" ]; then
        echo "TINFOIL_API_KEY not set in ${envFile}; not starting" >&2
        exit 0
      fi
      export MAPLE_API_KEY="''${MAPLE_API_KEY:-}"
      # ccr idles if its pid file names a live process, even one from a
      # manual run, and the service is the only legitimate instance.
      rm -f "$HOME/.claude-code-router/.claude-code-router.pid"
      exec ccr start
    '';
  };

  router = mkService "Claude Code Router" (lib.getExe routerStart);

  # Seeds each session's fresh config dir, so it skips first-run screens.
  seedConfig = pkgs.writeText "claude-confidential.json" (builtins.toJSON {
    hasCompletedOnboarding = true;
    hasSeenAutoDefaultNotice = true;
  });
  seedSettings = pkgs.writeText "claude-confidential-settings.json"
    (builtins.toJSON { theme = "dark"; });

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Creates `$dir`, a session state dir in RAM that only this user can
  # reach, and defines `drop` to delete it.
  mkSessionDir =
    if isDarwin then ''
      # RAM disk pages are allocated as written, so the size is only a cap.
      dev=$(/usr/sbin/diskutil image attach --noMount ram://4G)
      /sbin/newfs_hfs "$dev" > /dev/null
      dir=$(mktemp -d "${stateDir}/ram.XXXXXX")
      /usr/sbin/diskutil mount -mountOptions nobrowse -mountPoint "$dir" \
        "$dev" > /dev/null
      drop() {
        /usr/sbin/diskutil unmountDisk force "$dev"
        /usr/sbin/diskutil eject "$dev"
        rmdir "$dir"
      }
    '' else ''
      : "''${XDG_RUNTIME_DIR:?not set, so there is no tmpfs for session state}"
      dir=$(mktemp -d "$XDG_RUNTIME_DIR/claude-confidential.XXXXXX")
      drop() { rm -rf "$dir"; }
    '';

  # Claude Code's cache dir, where it writes per-cwd MCP server logs.
  claudeCache =
    if isDarwin then "$HOME/Library/Caches/claude-cli-nodejs"
    else "\${XDG_CACHE_HOME:-$HOME/.cache}/claude-cli-nodejs";

  # Creates `$dir` in RAM, seeded, for the session's config and temp
  # files, and drops it with the session's MCP logs once claude exits.
  inMemorySession = ''
    ${mkSessionDir}
    # MCP server logs land outside `$dir`, in files whose lines carry the
    # session ID. The session's IDs name its transcripts and appear in its
    # config and session records.
    drop_mcp_logs() {
      local ids
      ids=$({
        printf '%s\n' "$dir"/projects/*/*.jsonl
        cat "$dir/.claude.json" "$dir"/sessions/*.json
      } 2> /dev/null | grep -oE '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}')
      [ -n "$ids" ] && grep -rlF "$ids" "${claudeCache}" | xargs rm -f
    }

    # Drop the session's state once claude, which inherits this PID,
    # exits. Double-forked to leave claude's process tree, which Paseo
    # kills. A failed step must not stop the rest, so errexit is off.
    pid=$$
    ( (
      set +e
      trap "" HUP INT TERM
      while kill -0 "$pid" 2> /dev/null; do sleep 1; done
      drop_mcp_logs
      drop
    ) < /dev/null > /dev/null 2>&1 & )

    install -m 600 ${seedConfig} "$dir/.claude.json"
    install -m 600 ${seedSettings} "$dir/settings.json"
    install -d -m 700 "$dir/tmp"
    export CLAUDE_CODE_TMPDIR="$dir/tmp"
    export TMPDIR="$dir/tmp"
  '';

  wrapper = pkgs.writeShellApplication {
    name = "claude-confidential";
    runtimeInputs = with pkgs; [
      claude-code
      coreutils
      findutils
      gnugrep
    ];
    text = ''
      if [ -z "''${TINFOIL_API_KEY:-}" ]; then
        # shellcheck disable=SC1091
        [ -f "${envFile}" ] && . "${envFile}"
      fi
      : "''${TINFOIL_API_KEY:?not set in ${envFile}}"

      ${if cfg.inMemorySessions then inMemorySession else ''
        dir="${stateDir}"
      ''}
      export ANTHROPIC_BASE_URL="http://127.0.0.1:${toString routerPort}"
      export ANTHROPIC_AUTH_TOKEN="$TINFOIL_API_KEY"
      export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
      export CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL=1
      export CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576
      export CLAUDE_CONFIG_DIR="$dir"
      # `--mcp-config` is variadic, so it goes after the caller's arguments.
      exec claude "$@" --strict-mcp-config \
        --mcp-config "${stateDir}/mcp-servers.json"
    '';
  };

  # Runs after claudeMcpSync, which fills in the servers' credentials.
  writeMcpConfig = pkgs.writeShellApplication {
    name = "claude-confidential-mcp";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      jq --argjson keep \
        '${builtins.toJSON config.claude-mcp.confidentialServers}' '
        { mcpServers: ((.mcpServers // {})
            | with_entries(select(.key as $k | $keep | index($k)))) }
      ' "$HOME/.claude.json" > "${stateDir}/mcp-servers.json"
    '';
  };

  sync = pkgs.writeShellApplication {
    name = "confidential-sync";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = builtins.readFile ./confidential-sync.sh;
  };
in
{
  imports = [
    ./claude-mcp.nix
    ./maple.nix
    ./tinfoil.nix
  ];

  options.confidential.inMemorySessions = lib.mkEnableOption ''
    keeping `claude-confidential` session state in RAM, dropped with its
    MCP logs when the session exits, so nothing can be resumed, not even
    a Paseo agent whose process has exited. Otherwise sessions persist in
    the private state dir under Claude Code's idle cleanup'';

  config = {
    home.packages = [ claude-code-router wrapper ];

    # Nix-owned, so `ccr model` / `ccr ui` edits won't stick.
    home.file.".claude-code-router/config.json".text =
      builtins.toJSON routerConfig;

    systemd.user.services.claude-code-router = router.systemd;
    launchd.agents.claude-code-router = router.launchd;

    # Paseo resolves a provider's command without the daemon's PATH, so
    # it gets the wrapper's profile path, which exists once packages are
    # installed.
    home.activation.confidentialSync =
      lib.hm.dag.entryAfter [ "installPackages" ] ''
        PASEO_BIN=${paseo}/bin/paseo \
          WRAPPER=${config.home.profileDirectory}/bin/${wrapper.name} \
          ${sync}/bin/confidential-sync
      '';

    # `home.file` would create the parents 0755, so install by hand.
    home.activation.claudeConfidentialMcp =
      lib.hm.dag.entryAfter [ "claudeMcpSync" ] ''
        run install -d -m 700 "${stateDir}"
        run ${lib.getExe writeMcpConfig}
      '';
  };
}
