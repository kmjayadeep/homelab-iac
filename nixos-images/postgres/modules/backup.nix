{ config, lib, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    restic
  ];

  environment.etc.restic-env.source = ../secrets/secret-restic.env;

  systemd.services.backup-postgres = {
    description = "Backup the Postgres db using restic";
    wants = ["network-online.target"];
    after = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    script = ''
      set -eu
      mkdir -p /tmp/postgres-backup
      source /etc/restic-env
      for DB_NAME in totp planka immich coder; do
        ${pkgs.postgresql_16}/bin/pg_dump -c -d "''$DB_NAME" -F tar -f "/tmp/postgres-backup/''${DB_NAME}_backup.tar"
      done
      ls /tmp/postgres-backup
      ${pkgs.restic}/bin/restic backup /tmp/postgres-backup
      ${pkgs.restic}/bin/restic forget --keep-monthly 12 --keep-last 10 --keep-daily 10 --prune
      ${pkgs.restic}/bin/restic snapshots
      mkdir -p /tmp/postgres-backup-prev
      mv /tmp/postgres-backup/* /tmp/postgres-backup-prev
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
