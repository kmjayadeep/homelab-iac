# Phase 2: Admin Interface

Status: Not started

## Goal

Give the platform admin a simple, repeatable interface for common Postgres operations.

## Current state

- Rebuild command exists in `nixos-images/postgres/Makefile`.
- Admin tasks are mostly manual: edit Nix, rebuild, run `psql`, inspect systemd logs.
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

## Proposed implementation

Add `nixos-images/postgres/justfile` with commands that SSH to Helios and wrap safe operations.

Initial low-risk commands:

- `rebuild` - existing NixOS rebuild
- `psql` - open psql as postgres/admin
- `db-list` - list databases
- `db-size` - show database sizes
- `db-backup-now` - start `backup-postgres.service`
- `db-backup-status` - show backup service and timer state
- `db-backup-logs` - show recent backup logs
- `db-snapshots` - list Restic snapshots

Later commands:

- `db-restore`
- `db-onboard`
- `db-rotate-password`
- `db-readonly-user`

## Deliverables

- [ ] Add `justfile` under `nixos-images/postgres/`.
- [ ] Keep commands read-only or operationally safe at first.
- [ ] Document each command in `nixos-images/postgres/README.md`.
- [ ] Add restore-related commands only after restore runbook is validated.

## Validation

- Common admin checks do not require remembering long SSH/systemd/psql commands.
- Backup status can be checked with one command.
- Manual backup can be triggered with one command.
