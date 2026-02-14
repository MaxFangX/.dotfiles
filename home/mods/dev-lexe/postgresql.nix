# User-level PostgreSQL for Lexe local development.
# Runs as a systemd user service — no sudo or apt required.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  isLinux = pkgs.hostPlatform.isLinux;

  pg = pkgs.postgresql;
  dataDir =
    "${config.home.homeDirectory}/.local/share/postgresql";
  port = "5432";
  superUser = config.home.username;

  # Lexe dev credentials
  lexeUser = "lxuser1";
  lexePass = "sadge";
  lexeDb = "lexe-dev-db1";

  pgHbaConf = pkgs.writeText "pg_hba.conf" ''
    # Peer auth for the OS user (admin)
    local  all  ${superUser}  peer
    # Password auth for all other local socket connections
    local  all  all           scram-sha-256
    # Password auth for TCP connections from localhost
    host   all  all  127.0.0.1/32  scram-sha-256
    host   all  all  ::1/128       scram-sha-256
  '';

  postgresqlConf = pkgs.writeText "postgresql.conf" ''
    listen_addresses = 'localhost'
    port = ${port}
    password_encryption = 'scram-sha-256'
    unix_socket_directories = '${dataDir}'
  '';

  # Idempotent init: create cluster + link config files.
  initScript = pkgs.writeShellScript "pg-init" ''
    set -euo pipefail
    if [ ! -f "${dataDir}/PG_VERSION" ]; then
      echo "pg-init: initializing cluster..."
      mkdir -p "${dataDir}"
      ${pg}/bin/initdb \
        -D "${dataDir}" -U "${superUser}" --auth=peer
    fi
    ln -sf ${postgresqlConf} "${dataDir}/postgresql.conf"
    ln -sf ${pgHbaConf}      "${dataDir}/pg_hba.conf"
  '';

  # Idempotent setup: create Lexe role + database.
  setupScript = pkgs.writeShellScript "pg-setup-lexe" ''
    set -euo pipefail
    export PGHOST="${dataDir}"

    # Wait for postgres to accept connections (max 30s)
    for i in $(seq 1 30); do
      if ${pg}/bin/pg_isready -q -U "${superUser}" -d postgres; then
        break
      fi
      sleep 1
    done

    psql="${pg}/bin/psql -U ${superUser} -d postgres"

    # Create role if missing
    if ! $psql -tAc \
         "SELECT 1 FROM pg_roles WHERE rolname='${lexeUser}'" \
         | grep -q 1; then
      $psql -c "CREATE ROLE ${lexeUser} WITH
        LOGIN PASSWORD '${lexePass}' CREATEDB SUPERUSER;"
      echo "pg-setup: created role ${lexeUser}"
    fi

    # Create database if missing
    if ! $psql -tAc \
         "SELECT 1 FROM pg_database
           WHERE datname='${lexeDb}'" \
         | grep -q 1; then
      ${pg}/bin/createdb -U "${superUser}" \
        -O "${lexeUser}" "${lexeDb}"
      echo "pg-setup: created database ${lexeDb}"
    fi
  '';
in
{
  config = lib.mkIf isLinux {
    home.packages = [ pg ];

    systemd.user.services.postgresql = {
      Install.WantedBy = [ "default.target" ];

      Unit = {
        Description = "PostgreSQL (user service)";
      };

      Service = {
        Type = "notify";
        ExecStartPre = "${initScript}";
        ExecStart =
          "${pg}/bin/postgres -D ${dataDir}";
        ExecStartPost = "${setupScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    home.sessionVariables = {
      PGDATA = dataDir;
      PGHOST = dataDir;
    };
  };
}
