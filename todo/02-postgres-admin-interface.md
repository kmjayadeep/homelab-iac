# Phase 2: Admin Interface

Status: Done

## Goal

Give the platform admin a simple, repeatable interface for common Postgres operations.

## Current state

- Rebuild command exists in `nixos-images/postgres/Makefile`.
- `nixos-images/postgres/justfile` now wraps common admin operations.
- pgweb exists for visual inspection but is not a lifecycle-management interface.

## Desired experience

Examples:

```bash
just rebuild
just psql
just db-list
just db-size
just db-backup-now
just db-backup-status
just db-snapshots
just db-restore immich latest immich_restore
```

Eventually:

```bash
just db-onboard myapp
just db-rotate-password myapp
just db-decommission myapp
```

## Implemented interface

Added `nixos-images/postgres/justfile` with commands that SSH to Helios and wrap safe operations.

Implemented commands:

- `rebuild` - existing NixOS rebuild.
- `psql` - open psql as postgres/admin.
- `db-list` - list non-template databases.
- `db-size` - show database sizes.
- `db-backup-now` - start `backup-postgres.service`.
- `db-backup-status` - show backup service and timer state.
- `db-backup-logs` - show recent backup logs.
- `db-snapshots` - list Restic snapshots.
- `db-snapshot-files` - list Postgres backup files in the latest Restic snapshot.
- `db-inspect-staging` - inspect local backup staging output and metadata.
- `db-check-dumps` - validate local custom-format dumps with `pg_restore -l`.
- `db-restore-help` - point to documented restore procedures without wrapping restore yet.

Deferred commands:

- `db-restore`
- `db-onboard`
- `db-rotate-password`
- `db-readonly-user`

## Deliverables

- [x] Add `justfile` under `nixos-images/postgres/`.
- [x] Keep commands read-only or operationally safe at first.
- [x] Document each command in `nixos-images/postgres/README.md`.
- [x] Keep restore operations documented only; do not add `db-restore` until restore testing is validated.

## Validation

- Common admin checks do not require remembering long SSH/systemd/psql commands.
- Backup status can be checked with one command.
- Manual backup can be triggered with one command.
