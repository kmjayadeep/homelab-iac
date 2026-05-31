# Phase 5: Backup Health and Restore Automation

Status: Not started

## Goal

Move from "backups are configured" to "backups are known-good and monitored".

## Current state

- Hourly backup timer exists.
- Restic repository is used.
- Restore confidence is documented as `Medium` in `inventory/backups.md`.
- No restore test date/result is recorded.

## Proposed improvements

### Backup freshness marker

At the end of a successful backup, write a marker such as:

```text
/var/lib/postgres-platform/last_backup_success
```

Include:

- timestamp
- snapshot id
- DB list
- result

Expose this via:

- node textfile collector, if available
- a simple script checked by monitoring
- systemd status/logs as a minimum

### Restic check

Add a periodic timer:

```bash
restic check
```

Recommended cadence:

- daily or weekly for homelab
- alert on failure

### Restore test

Start manually, then automate later.

Manual flow:

1. Restore latest snapshot to temp directory.
2. Create temporary database, e.g. `restore_test`.
3. Restore one DB dump.
4. Run validation query.
5. Drop temporary database.
6. Record result/date.

Potential automated flow:

- use a tiny canary database
- insert/update known row before backup
- restore latest canary dump
- verify expected row exists

## Deliverables

- [ ] Add backup success marker.
- [ ] Add Restic check timer.
- [ ] Add manual restore runbook.
- [ ] Perform first restore test.
- [ ] Record restore test in `inventory/backups.md`.
- [ ] Decide whether to automate canary restore tests.

## Validation

- If backups stop, an alert fires.
- If Restic repository is unhealthy, an alert fires.
- A restore has been tested and documented.
- Restore process is understandable under pressure.
