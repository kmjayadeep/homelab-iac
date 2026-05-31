# Phase 1: Backup Correctness

Status: In progress

## Goal

Make sure every declared platform database is backed up unless explicitly excluded, and make restores predictable.

## Current state

Declared databases in `nixos-images/postgres/modules/postgres.nix`:

- `planka`
- `totp`
- `immich`
- `coder`
- `shoppinglist`
- `uptimekuma`
- `taskplanner`
- `k3s`

Backed up in `nixos-images/postgres/modules/backup.nix`:

- `totp`
- `planka`
- `immich`
- `coder`
- `taskplanner`

Missing from current backup loop:

- `shoppinglist`
- `uptimekuma`
- `k3s`

## Problems to fix

- Database declaration and backup list can drift.
- Roles/globals are not obviously backed up.
- There is no restore test recorded.
- Backup success is not clearly exposed as a platform health signal.

## Implemented approach

Phase 1 uses a hybrid logical backup:

1. Back up all current application databases.
2. Exclude system databases (`postgres`, `template0`, `template1`) from per-database dumps.
3. Include Postgres globals backup:

   ```bash
   pg_dumpall --globals-only
   ```

4. Use per-database custom-format dumps:

   ```bash
   pg_dump -F c -d "$DB_NAME" -f "$DB_NAME.dump"
   ```

5. Include backup metadata:
   - start/finish timestamp
   - hostname
   - Postgres version
   - list of DBs included
   - retention target
   - dump sizes

6. Keep one previous local backup under `/var/tmp/postgres-backup/previous`.
7. Upload only `/var/tmp/postgres-backup/current` to Restic.

A shared database catalog is still deferred to Phase 3.

## Deliverables

- [x] Fix immediate backup drift by adding missing DBs or explicitly excluding them.
- [x] Add globals/roles backup.
- [x] Add metadata file to each backup run.
- [x] Decide dump format: custom format (`pg_dump -F c`) plus `globals.sql`.
- [x] Document restore commands for the chosen format.
- [ ] Add a manual restore test and record date/result.

## Validation

- `backup-postgres.service` backs up all intended DBs.
- Restic snapshot contains DB dumps and metadata.
- At least one DB can be restored into a test database.
- `inventory/backups.md` confidence can move from `Medium` toward `High` after restore testing.
