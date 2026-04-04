# PostgreSQL service tuned for integration tests.
#
# macOS: launchd agent, connect via `PGHOST=$HOME/.local/share/postgresql`
# Linux: systemd user service, connect via `PGHOST=$XDG_RUNTIME_DIR`
#
# DO NOT USE THIS IN PRODUCTION.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    literalExpression
    makeBinPath
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;

  cfg = config.services.postgres;
  pkg = cfg.package;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Platform-specific paths
  dataDir = cfg.dataDir;
  logDir = "${config.home.homeDirectory}/.local/log";
  socketDir =
    if isLinux then "$XDG_RUNTIME_DIR"
    else dataDir;

  postgresqlConf = pkgs.writeText "postgresql.conf" ''
    # Connection settings
    listen_addresses = 'localhost'
    port = 5432
    unix_socket_directories = '${dataDir}'
    unix_socket_permissions = 0700
    password_encryption = 'scram-sha-256'
    ssl = off
    max_connections = 64

    # Remove brakes
    fsync = off
    synchronous_commit = off
    full_page_writes = off
    commit_delay = 0
    commit_siblings = 0
    wal_sync_method = open_sync  # (allegedly) fastest method when fsync is off

    # WAL settings
    wal_level = minimal                 # minimal WAL logging
    max_wal_senders = 0                 # no replication
    wal_buffers = 64MB                  # larger WAL buffer for faster writes
    checkpoint_timeout = 60min          # infrequent checkpoints
    checkpoint_completion_target = 0.9  # spread checkpoint writes
    max_wal_size = 2GB                  # max size of WAL files
    min_wal_size = 1GB                  # min size of WAL files
    wal_compression = off

    # Tune resource usage
    shared_buffers = 2GB          # cache for frequently accessed data
    work_mem = 16MB               # memory for sorts, hashes, and joins
    maintenance_work_mem = 256MB  # for VACUUM, CREATE INDEX, ALTER TABLE, etc.
    temp_buffers = 32MB           # for temporary tables
    effective_cache_size = 4GB    # hint for query planner

    # Tune query planner
    random_page_cost = 1.0          # assume everything is in memory
    effective_io_concurrency = ${if isLinux then "200" else "0"}
    seq_page_cost = 1.0             # sequential read cost
    jit = off                       # disable JIT compilation

    # Autovacuum - run only when idle
    autovacuum = on
    autovacuum_max_workers = 2            # Fewer workers when active
    autovacuum_naptime = 5min             # Check more frequently when idle
    autovacuum_vacuum_threshold = 1000    # Higher threshold
    autovacuum_analyze_threshold = 1000   # Higher threshold
    autovacuum_vacuum_scale_factor = 0.4  # Less aggressive
    autovacuum_analyze_scale_factor = 0.2 # Less aggressive
    autovacuum_vacuum_cost_delay = 10ms   # Slower when it runs
    autovacuum_vacuum_cost_limit = 1000   # Limit vacuum impact

    # Background writer - more aggressive when idle
    bgwriter_delay = 1000ms     # Check more frequently
    bgwriter_lru_maxpages = 0   # Disable LRU writes
    bgwriter_flush_after = 0    # Disable flush-after
    backend_flush_after = 0     # Disable backend flush

    # Statement
    statement_timeout = 10s                    # kill long-running test queries
    lock_timeout = 10s                         # don't wait long for locks
    idle_in_transaction_session_timeout = 10s # kill idle transactions

    # Reduce logging
    log_destination = 'stderr'
    log_line_prefix = '''
    logging_collector = off
    log_statement = 'none'
    log_duration = off
    log_lock_waits = on                 # debug deadlocks
    log_error_verbosity = terse
    log_connections = off
    log_disconnections = off
    log_hostname = off
    log_min_messages = warning
    log_checkpoints = off
    log_autovacuum_min_duration = 10s   # Only log slow autovacuum
  '';

  pgHbaConf = pkgs.writeText "pg_hba.conf" ''
    # Type  DB   User       Addr         Method
    local   all  ${config.home.username}  peer
    local   all  all                      scram-sha-256
    host    all  all        127.0.0.1/32  scram-sha-256
    host    all  all        ::1/128       scram-sha-256
  '';

  # Idempotent init: create cluster + link config files.
  initScript = pkgs.writeShellScript "postgres-init" ''
    set -euo pipefail

    mkdir -p "${dataDir}" && chmod 700 "${dataDir}"
    mkdir -p "${logDir}"

    if [[ ! -e "${dataDir}/PG_VERSION" ]]; then
      rm -f "${dataDir}/*.conf"
      ${pkg}/bin/initdb \
        ${concatStringsSep " " cfg.initdbArgs} \
        -D "${dataDir}" \
        -U "${config.home.username}" \
        --auth=peer
      touch "${dataDir}/.first_startup"
    fi

    ln -sfn ${postgresqlConf} "${dataDir}/postgresql.conf"
    ln -sfn ${pgHbaConf} "${dataDir}/pg_hba.conf"
  '';

  # Idempotent setup: create roles + databases.
  setupScript = pkgs.writeShellScript "postgres-setup" ''
    set -euo pipefail
    export PGHOST="${dataDir}"

    # Wait for postgres to accept connections (max 30s)
    for i in $(seq 1 30); do
      if ${pkg}/bin/pg_isready -q -U "${config.home.username}" -d postgres; then
        break
      fi
      sleep 1
    done

    psql="${pkg}/bin/psql -U ${config.home.username} -d postgres"

    # Run initial script on first startup if set
    if [[ -e "${dataDir}/.first_startup" ]]; then
      ${optionalString (cfg.initialScript != null)
        "$psql -f \"${cfg.initialScript}\""}
      rm "${dataDir}/.first_startup"
    fi

    # Ensure users exist
    ${concatMapStringsSep "\n" (user: ''
      if ! $psql -tAc \
           "SELECT 1 FROM pg_roles WHERE rolname='${user.name}'" \
           | grep -q 1; then
        $psql -c "CREATE ROLE ${user.name} WITH \
          LOGIN PASSWORD '${user.password}' CREATEDB SUPERUSER;"
        echo "postgres-setup: created role ${user.name}"
      fi
    '') cfg.ensureUsers}

    # Ensure databases exist
    ${concatMapStringsSep "\n" (db: ''
      if ! $psql -tAc \
           "SELECT 1 FROM pg_database WHERE datname='${db.name}'" \
           | grep -q 1; then
        ${pkg}/bin/createdb -U "${config.home.username}" \
          ${optionalString (db.owner != null) "-O \"${db.owner}\""} \
          "${db.name}"
        echo "postgres-setup: created database ${db.name}"
      fi
    '') cfg.ensureDatabases}
  '';
in
{
  options.services.postgres = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable PostgreSQL";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.postgresql_17;
      description = "PostgreSQL package to use";
    };

    dataDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/share/postgresql";
      description = "Directory for PostgreSQL data files";
    };

    initdbArgs = mkOption {
      type = types.listOf types.str;
      default = [
        "--encoding=UTF8"
        "--locale=C"
      ];
      description = "Arguments to pass to initdb.";
    };

    initialScript = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression ''
        pkgs.writeText "init-sql-script" '''
          alter user postgres with password 'myPassword';
        ''';
      '';
      description = "SQL statements to execute on first startup.";
    };

    ensureUsers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Username";
          };
          password = mkOption {
            type = types.str;
            description = "Password";
          };
        };
      });
      default = [ ];
      description = "Users to create with LOGIN, CREATEDB, SUPERUSER.";
      example = [
        { name = "myuser"; password = "mypass"; }
      ];
    };

    ensureDatabases = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Database name";
          };
          owner = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Database owner";
          };
        };
      });
      default = [ ];
      description = "Databases to create.";
      example = [
        { name = "mydb"; owner = "myuser"; }
      ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Common config
    {
      home.packages = [ pkg ];
      home.sessionVariables.PGHOST = dataDir;
    }

    # macOS: launchd agent
    (mkIf isDarwin {
      launchd.agents.postgresql = {
        enable = true;
        config = {
          Program = toString (pkgs.writeShellScript "run-postgres" ''
            ${initScript}
            ${pkg}/bin/pg_ctl -D "${dataDir}" -l "${logDir}/postgresql.log" start
            ${setupScript}
            # Keep the agent alive by tailing the log
            exec tail -f "${logDir}/postgresql.log"
          '');
          EnvironmentVariables.LC_ALL = "C";
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${logDir}/postgresql-agent.log";
          StandardErrorPath = "${logDir}/postgresql-agent.log";
        };
      };
    })

    # Linux: systemd user service
    (mkIf isLinux {
      systemd.user.services.postgres = {
        Install.WantedBy = [ "default.target" ];

        Unit.Description = "PostgreSQL v${pkg.version} DB server";

        Service = {
          Type = "notify";

          Environment = [
            "PATH=${makeBinPath [ pkg pkgs.coreutils pkgs.gnugrep ]}"
            "PGDATA=${dataDir}"
            "PGHOST=${dataDir}"
          ];

          ExecStartPre = "+${initScript}";
          ExecStart = "${pkg}/bin/postgres -D ${dataDir}";
          ExecStartPost = "+${setupScript}";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";

          KillSignal = "SIGINT";
          KillMode = "mixed";
          TimeoutSec = 60;
          Restart = "on-failure";
          RestartSec = 5;

          # Hardening
          ReadWritePaths = [ dataDir ];
          DevicePolicy = "closed";
          PrivateTmp = true;
          ProtectHome = "read-only";
          ProtectSystem = "strict";
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          ProcSubset = "pid";
          ProtectProc = "invisible";
          RemoveIPC = true;
          RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
        };
      };
    })
  ]);
}
