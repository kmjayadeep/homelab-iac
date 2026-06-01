# Phase 7: Reliability Upgrades

Status: Not started

## Goal

Evaluate optional reliability improvements after the basics are solid.

## Current state

- Helios VM: 2 cores, 2GB RAM, 100G disk.
- Postgres, MongoDB, nginx, pgweb, exporters, and backup jobs run on the same VM.
- No automatic failover.
- No standby replica.
- Backups are logical dumps to Cloudflare R2.

## Candidate upgrades

### Increase VM memory

This is the simplest improvement.

Current:

```hcl
memory = 2048
```

Candidate:

```hcl
memory = 4096
```

or higher if available.

Benefit:

- better Postgres cache behavior
- fewer memory pressure issues
- better room for MongoDB and exporters

### Tune Postgres memory

After increasing memory, add conservative settings:

```nix
services.postgresql.settings = {
  shared_buffers = "1GB";
  effective_cache_size = "3GB";
  maintenance_work_mem = "256MB";
  work_mem = "8MB";
};
```

Exact values should match final VM memory.

### WAL/PITR

Consider `pgBackRest` or `WAL-G` if hourly dump RPO is not enough.

Benefit:

- point-in-time recovery
- better recovery from accidental writes/drops

Cost:

- more complexity
- more operational knowledge needed

### Read replica standby

Add a second Postgres VM on another Proxmox node as an async read replica standby.

This is desired eventually, but should come after the standby-from-backup restore target is working and restore drills are trusted.

Initial mode should be manual failover only:

```text
helios primary -> streaming replication -> read replica standby
postgres.cosmos.cboxlab.com -> helios normally
manual failover -> promote replica, then update DNS
```

Benefit:

- faster manual recovery for primary VM/host failure
- can validate streaming replication health
- may support read-only checks or future read-only workloads
- gives a path from restore-target standby toward a more cloud-like database service

Important limitation:

- app mistakes, bad migrations, accidental deletes, and data corruption can replicate to the standby. Backups and PITR are still required.

Cost:

- more moving parts
- replication monitoring required
- promotion/failback process must be documented and tested
- split-brain risk if failover is automated too early

## Recommended order

1. Increase memory if resource budget allows.
2. Tune Postgres memory settings.
3. Consider WAL/PITR only after dump restores are tested.
4. Build and validate standby-from-backup first.
5. Consider read replica standby only after monitoring, backup health, and restore drills are reliable.

## Deliverables

- [ ] Decide whether Helios should move from 2GB to 4GB RAM.
- [ ] Add Postgres memory tuning after RAM decision.
- [ ] Decide whether hourly RPO is enough.
- [ ] Evaluate WAL/PITR later.
- [ ] Evaluate read replica standby later after standby-from-backup is working.

## Validation

- Reliability changes are backed by monitoring, not guesswork.
- Added complexity has a documented runbook.
- Backups and restore tests remain the primary safety net.
