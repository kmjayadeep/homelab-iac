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

### Backup efficiency optimization

Review the dump + Restic strategy using this reference:

- <https://strugglers.net/posts/2025/database-backups-dump-files-and-restic/>

Current Phase 1 layout is operationally good, but later optimization should check whether compressed dump files reduce Restic deduplication efficiency. Consider testing options such as:

- custom-format dumps with compression disabled: `pg_dump -F c -Z 0`
- directory-format dumps: `pg_dump -F d`
- splitting large/churn-heavy databases into more dedupe-friendly files
- measuring actual Restic repository growth across hourly snapshots before changing strategy

### Multi-target backup strategy

Evaluate using local MinIO on TrueNAS as an additional backup target.

Rationale:

- MinIO is local, so frequent or heavier snapshots are cheaper and faster.
- Cloudflare R2 is offsite, so it should remain the disaster-recovery target.
- Local MinIO can carry short-interval operational restores.
- Cloud snapshots can potentially run less frequently once local backup health is proven.

Possible future policy:

| Target | Location | Purpose | Candidate frequency |
| --- | --- | --- | --- |
| MinIO on TrueNAS | Local | frequent operational restore points | every 15 minutes or hourly |
| Cloudflare R2 | Offsite | disaster recovery | hourly, every 4 hours, or daily depending on measured cost/size |

Questions to answer before implementation:

- Should MinIO use a separate Restic repository or mirror the same backup output through a second repository?
- What retention should local MinIO use versus Cloudflare R2?
- Should local backups include more frequent snapshots or heavier dump formats optimized for Restic dedupe?
- How should alerts distinguish local backup failure from offsite backup failure?
- Is TrueNAS/MinIO itself sufficiently protected by NAS snapshots or replication?

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
