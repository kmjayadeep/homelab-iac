{ config, lib, pkgs, ... }:

let
  backupDatabases = [
    "planka"
    "totp"
    "immich"
    "coder"
    "shoppinglist"
    "uptimekuma"
    "taskplanner"
    "k3s"
  ];
  backupDatabaseList = lib.concatStringsSep " " backupDatabases;
  backupDatabaseJson = builtins.toJSON backupDatabases;
in
{
  environment.systemPackages = with pkgs; [
    restic
  ];

  environment.etc.restic-env.source = ../secrets/secret-restic.env;

  systemd.services.backup-postgres = {
    description = "Backup the Postgres db using restic";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    script = ''
      set -eu

      BACKUP_ROOT="/var/tmp/postgres-backup"
      CURRENT_DIR="''$BACKUP_ROOT/current"
      PREVIOUS_DIR="''$BACKUP_ROOT/previous"
      DATABASES="${backupDatabaseList}"

      source /etc/restic-env

      rm -rf "''$PREVIOUS_DIR"
      if [ -d "''$CURRENT_DIR" ]; then
        mv "''$CURRENT_DIR" "''$PREVIOUS_DIR"
      fi
      mkdir -p "''$CURRENT_DIR/databases"

      BACKUP_STARTED_AT="$(${pkgs.coreutils}/bin/date --utc --iso-8601=seconds)"
      HOSTNAME="$(${pkgs.coreutils}/bin/cat /proc/sys/kernel/hostname)"
      POSTGRES_VERSION="$(${pkgs.postgresql_16}/bin/psql -Atc 'SHOW server_version;')"

      ${pkgs.postgresql_16}/bin/pg_dumpall --globals-only -f "''$CURRENT_DIR/globals.sql"

      for DB_NAME in ''$DATABASES; do
        ${pkgs.postgresql_16}/bin/pg_dump -d "''$DB_NAME" -F c -f "''$CURRENT_DIR/databases/''${DB_NAME}.dump"
      done

      BACKUP_FINISHED_AT="$(${pkgs.coreutils}/bin/date --utc --iso-8601=seconds)"

      {
        echo "{"
        echo "  \"backup_started_at\": \"''$BACKUP_STARTED_AT\","
        echo "  \"backup_finished_at\": \"''$BACKUP_FINISHED_AT\","
        echo "  \"hostname\": \"''$HOSTNAME\","
        echo "  \"postgres_version\": \"''$POSTGRES_VERSION\","
        echo "  \"format\": \"pg_dump custom + globals sql\","
        echo "  \"rpo\": \"<= 1 hour\","
        echo "  \"retention\": \"keep_last=10, keep_daily=10, keep_monthly=12\","
        echo "  \"databases\": ${backupDatabaseJson},"
        echo "  \"dump_sizes_bytes\": {"
        FIRST=1
        for DB_NAME in ''$DATABASES; do
          SIZE="$(${pkgs.coreutils}/bin/stat -c%s "''$CURRENT_DIR/databases/''${DB_NAME}.dump")"
          if [ "''$FIRST" = 1 ]; then
            FIRST=0
          else
            printf ',\n'
          fi
          printf '    \"%s\": %s' "''$DB_NAME" "''$SIZE"
        done
        printf '\n  }\n}\n'
      } > "''$CURRENT_DIR/metadata.json"

      ${pkgs.coreutils}/bin/ls -lah "''$CURRENT_DIR" "''$CURRENT_DIR/databases"
      ${pkgs.restic}/bin/restic backup "''$CURRENT_DIR"
      ${pkgs.restic}/bin/restic forget --keep-monthly 12 --keep-last 10 --keep-daily 10 --prune
      ${pkgs.restic}/bin/restic snapshots
    '';
  };

  systemd.timers.backup-postgres = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

}
