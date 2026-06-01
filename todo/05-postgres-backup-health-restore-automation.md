# Phase 5: Backup Health and Restore Automation

Status: Not started

## Goal

Move from "backups are configured" to "backups are known-good and monitored". This phase should also prove that a new NixOS standby/restore-target VM can be built and fully restored from backup.

## Current state

- Hourly backup timer exists.
- Restic repository is used.
- Restore confidence is documented as `Medium` in `inventory/backups.md`.
- No restore test date/result is recorded.
- No standby/restore-target VM exists yet for full disaster-recovery drills.

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

### Standby/restore-target VM

Set up a dedicated NixOS VM that can be used as a warm standby from backup and as a safe restore-test target.

Purpose:

- prove a replacement Postgres host can be built from infrastructure-as-code
- run full restore tests without risking Helios
- reduce disaster-recovery uncertainty
- eventually provide a manual DNS failover target

Initial design:

```text
helios = primary Postgres VM
<standby> = NixOS restore-target / warm standby
postgres.cosmos.cboxlab.com = points to Helios normally
postgres-standby.cosmos.cboxlab.com = points to restore-target VM
```

The standby VM should be NixOS-managed and should include:

- PostgreSQL 16
- required extensions, including `pgvector`
- Restic and PostgreSQL client/restore tools
- same base operator SSH access
- monitoring exporters if useful
- no production app traffic by default
- no automatic failover initially

Terraform/Proxmox should own:

- VM creation
- static IP
- DNS record
- disk size
- CPU/RAM
- SSH keys

NixOS should own:

- PostgreSQL packages and extensions
- restore tooling
- validation scripts
- optional monitoring exporter config

### Restore tests

Use two levels of restore testing.

#### Safe single-DB restore test

Run regularly and avoid overwriting existing databases.

Manual flow:

1. Restore latest snapshot to temp directory.
2. Create temporary database, e.g. `restore_test_uptimekuma`.
3. Restore one DB dump.
4. Run validation query.
5. Drop temporary database.
6. Record result/date.

#### Full standby restore test

Run on the dedicated standby/restore-target VM.

Manual flow:

1. Build/provision the standby VM.
2. Install/apply the NixOS restore-target config.
3. Restore latest Restic snapshot to staging.
4. Restore `globals.sql`.
5. Create all application databases with the expected owners.
6. Restore every database dump.
7. Validate DB list, roles, extensions, and important DBs.
8. Record restore duration, backup snapshot ID, and result.
9. Keep the VM available as a warm standby or reset it for the next drill.

Potential automated flow:

- use a tiny canary database
- insert/update known row before backup
- restore latest canary dump on the standby VM
- verify expected row exists
- periodically run full restore drills manually until the process is trusted

## Deliverables

- [ ] Add backup success marker.
- [ ] Add Restic check timer.
- [ ] Add manual restore runbook.
- [ ] Add Terraform/Proxmox VM definition for the NixOS standby/restore-target.
- [ ] Add DNS record for the standby/restore-target.
- [ ] Add NixOS host config for the standby/restore-target.
- [ ] Add restore-target module/scripts for full restore and validation.
- [ ] Perform first safe single-DB restore test.
- [ ] Perform first full restore test on the standby VM.
- [ ] Record restore test date, snapshot ID, duration, and result in `inventory/backups.md`.
- [ ] Decide whether to automate canary restore tests.

## Validation

- If backups stop, an alert fires.
- If Restic repository is unhealthy, an alert fires.
- A safe single-DB restore has been tested and documented.
- A full restore to a dedicated NixOS standby VM has been tested and documented.
- The standby VM can be promoted manually by changing DNS after a successful restore.
- Restore process is understandable under pressure.
