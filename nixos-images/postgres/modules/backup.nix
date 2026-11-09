{ config, lib, pkgs, ... }:

let
  catalog = import ./postgres-catalog.nix;
  # Databases are discovered at backup time, so one missing from the catalog is
  # still backed up. Only an explicit `backup = false` opts out.
  excludedDatabases = [ "postgres" ] ++ builtins.attrNames (lib.filterAttrs (_: database: !(database.backup or true)) catalog.databases);
  excludedDatabaseSql = lib.concatMapStringsSep ", " (name: "'${name}'") excludedDatabases;
  resticRetention = "--keep-monthly 12 --keep-last 10 --keep-daily 10";
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
      StateDirectory = "postgres-backup";
    };

    script = ''
      set -euo pipefail

      BACKUP_ROOT="/var/tmp/postgres-backup"
      CURRENT_DIR="''$BACKUP_ROOT/current"
      PREVIOUS_DIR="''$BACKUP_ROOT/previous"
      STATUS_FILE="/var/lib/postgres-backup/status.json"
      BACKUP_STARTED_AT="$(${pkgs.coreutils}/bin/date --utc --iso-8601=seconds)"
      SNAPSHOT_ID=""
      SIZES="{}"

      write_status() {
        EXIT_CODE=$?
        ${pkgs.jq}/bin/jq -n \
          --arg started "''$BACKUP_STARTED_AT" \
          --arg finished "$(${pkgs.coreutils}/bin/date --utc --iso-8601=seconds)" \
          --arg snapshot "''$SNAPSHOT_ID" \
          --argjson exit_code "''$EXIT_CODE" \
          --argjson sizes "''$SIZES" \
          '{
            result: (if $exit_code == 0 then "success" else "failed" end),
            exit_code: $exit_code,
            started_at: $started,
            finished_at: $finished,
            snapshot_id: (if $snapshot == "" then null else $snapshot end),
            dump_sizes_bytes: $sizes,
            dump_total_bytes: ($sizes | add // 0)
          }' > "''$STATUS_FILE.tmp"
        ${pkgs.coreutils}/bin/mv "''$STATUS_FILE.tmp" "''$STATUS_FILE"
      }
      trap write_status EXIT

      source /etc/restic-env

      DATABASES="$(${pkgs.postgresql_16}/bin/psql -Atc "SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn AND datname NOT IN (${excludedDatabaseSql}) ORDER BY datname;")"
      if [ -z "''$DATABASES" ]; then
        echo "No databases found to back up" >&2
        exit 1
      fi

      rm -rf "''$PREVIOUS_DIR"
      if [ -d "''$CURRENT_DIR" ]; then
        mv "''$CURRENT_DIR" "''$PREVIOUS_DIR"
      fi
      mkdir -p "''$CURRENT_DIR/databases"

      HOSTNAME="$(${pkgs.coreutils}/bin/cat /proc/sys/kernel/hostname)"
      POSTGRES_VERSION="$(${pkgs.postgresql_16}/bin/psql -Atc 'SHOW server_version;')"

      ${pkgs.postgresql_16}/bin/pg_dumpall --globals-only -f "''$CURRENT_DIR/globals.sql"

      for DB_NAME in ''$DATABASES; do
        ${pkgs.postgresql_16}/bin/pg_dump -d "''$DB_NAME" -F c -f "''$CURRENT_DIR/databases/''${DB_NAME}.dump"
      done

      BACKUP_FINISHED_AT="$(${pkgs.coreutils}/bin/date --utc --iso-8601=seconds)"

      SIZES="$(
        for DB_NAME in ''$DATABASES; do
          printf '%s\t%s\n' "''$DB_NAME" "$(${pkgs.coreutils}/bin/stat -c%s "''$CURRENT_DIR/databases/''${DB_NAME}.dump")"
        done | ${pkgs.jq}/bin/jq -Rn '[inputs | split("\t") | {key: .[0], value: (.[1] | tonumber)}] | from_entries'
      )"

      ${pkgs.jq}/bin/jq -n \
        --arg started "''$BACKUP_STARTED_AT" \
        --arg finished "''$BACKUP_FINISHED_AT" \
        --arg hostname "''$HOSTNAME" \
        --arg version "''$POSTGRES_VERSION" \
        --argjson sizes "''$SIZES" \
        '{
          backup_started_at: $started,
          backup_finished_at: $finished,
          hostname: $hostname,
          postgres_version: $version,
          format: "pg_dump custom + globals sql",
          rpo: "<= 1 hour",
          retention: "keep_last=10, keep_daily=10, keep_monthly=12",
          databases: ($sizes | keys),
          dump_sizes_bytes: $sizes
        }' > "''$CURRENT_DIR/metadata.json"

      ${pkgs.coreutils}/bin/ls -lah "''$CURRENT_DIR" "''$CURRENT_DIR/databases"
      SUMMARY="$(${pkgs.restic}/bin/restic backup --retry-lock 30m --json "''$CURRENT_DIR" | ${pkgs.jq}/bin/jq -c 'select(.message_type == "summary")')"
      echo "''$SUMMARY"
      SNAPSHOT_ID="$(${pkgs.jq}/bin/jq -r '.snapshot_id' <<<"''$SUMMARY")"
    '';
  };

  systemd.services.backup-postgres-prune = {
    description = "Apply retention to the Postgres restic repository";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    script = ''
      set -eu
      source /etc/restic-env
      ${pkgs.restic}/bin/restic forget --retry-lock 30m ${resticRetention} --prune
      ${pkgs.restic}/bin/restic snapshots --no-lock
    '';
  };

  systemd.services.backup-postgres-check = {
    description = "Verify the Postgres restic repository";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    script = ''
      set -eu
      source /etc/restic-env
      ${pkgs.restic}/bin/restic check --retry-lock 30m
    '';
  };

  systemd.timers.backup-postgres = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # Both avoid the top of the hour, when the backup takes its restic lock.
  systemd.timers.backup-postgres-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
    };
  };

  systemd.timers.backup-postgres-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 04:30:00";
      Persistent = true;
    };
  };

}
