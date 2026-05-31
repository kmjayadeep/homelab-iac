# Phase 1: Backup Correctness

Status: Not started

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

## Proposed approach

1. Create one source of truth for Postgres databases.
2. Use that source for both database/user creation and backup selection.
3. Add a `backup = true/false` flag per DB.
4. Include Postgres globals backup:

   ```bash
   pg_dumpall --globals-only
   ```

5. Prefer per-database custom-format dumps if practical:

   ```bash
   pg_dump -F c -d "$DB_NAME" -f "$DB_NAME.dump"
   ```

6. Include backup metadata:
   - timestamp
   - hostname
   - Postgres version
   - list of DBs included
   - dump sizes

## Deliverables

- [ ] Fix immediate backup drift by adding missing DBs or explicitly excluding them.
- [ ] Add globals/roles backup.
- [ ] Add metadata file to each backup run.
- [ ] Decide dump format: current tar vs custom format.
- [ ] Document restore commands for the chosen format.
- [ ] Add a manual restore test and record date/result.

## Validation

- `backup-postgres.service` backs up all intended DBs.
- Restic snapshot contains DB dumps and metadata.
- At least one DB can be restored into a test database.
- `inventory/backups.md` confidence can move from `Medium` toward `High` after restore testing.
