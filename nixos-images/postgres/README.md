# Helios Databases

NixOS image and operational helpers for the `helios` database VM.

## Postgres platform

The user-facing service contract is documented in:

- [`../../docs/platform/postgres.md`](../../docs/platform/postgres.md)

Current platform details:

- Host VM: `helios`
- Current IP: `192.168.1.77`
- Canonical endpoint: `postgres.cosmos.cboxlab.com:5432`
- Network scope: LAN only
- PostgreSQL: 16
- Backups: hourly Restic snapshots with `globals.sql` plus per-database custom-format dumps

## Admin interface

Common admin operations are wrapped in `just` recipes. Run from this directory:

```bash
just --list
```

### Rebuild

```bash
just rebuild
```

Runs:

```bash
nixos-rebuild switch --flake .#helios --target-host root@postgres.cosmos.cboxlab.com --verbose
```

### Open psql

Open the default `postgres` database:

```bash
just psql
```

Open a specific database:

```bash
just psql immich
```

### List databases

```bash
just db-list
```

Lists non-template databases.

### Show database sizes

```bash
just db-size
```

Shows database sizes, largest first.

### Trigger a manual backup

```bash
just db-backup-now
```

Starts `backup-postgres.service` on Helios.

### Check backup status

```bash
just db-backup-status
```

Shows `backup-postgres.service` and `backup-postgres.timer` status.

### Show backup logs

```bash
just db-backup-logs
```

Override the number of lines:

```bash
just db-backup-logs 200
```

### List Restic snapshots

```bash
just db-snapshots
```

Sources `/etc/restic-env` on Helios and runs `restic snapshots` as the `postgres` user.

### List files in the latest Restic snapshot

```bash
just db-snapshot-files
```

Shows Postgres backup files in the latest Restic snapshot.

### Inspect backup staging output

```bash
just db-inspect-staging
```

Shows `/var/tmp/postgres-backup/current`, the database dump files, and `metadata.json` from the latest backup staging directory.

### Validate local dump files

```bash
just db-check-dumps
```

Runs `pg_restore -l` against every local `.dump` file in `/var/tmp/postgres-backup/current/databases`.

### Restore help

```bash
just db-restore-help
```

Restore commands are intentionally documented rather than wrapped for now. See:

- [`../../docs/platform/postgres.md`](../../docs/platform/postgres.md)

## MongoDB

MongoDB is also currently enabled on Helios.

Create user example:

```bash
use brokerme
db.createUser({
  user: "brokerme",
  pwd: "brokerme1234",
  roles: [
    { role: "readWrite", db: "brokerme" }
  ]
})
```
