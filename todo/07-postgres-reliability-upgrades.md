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

### Read replica

Add a second Postgres VM on another Proxmox node.

Initial mode should be manual failover only.

Benefit:

- replica can validate streaming backup/replication health
- faster manual recovery in some failures

Cost:

- more moving parts
- failover process must be documented and tested

## Recommended order

1. Increase memory if resource budget allows.
2. Tune Postgres memory settings.
3. Consider WAL/PITR only after dump restores are tested.
4. Consider read replica only after monitoring and backup health are reliable.

## Deliverables

- [ ] Decide whether Helios should move from 2GB to 4GB RAM.
- [ ] Add Postgres memory tuning after RAM decision.
- [ ] Decide whether hourly RPO is enough.
- [ ] Evaluate WAL/PITR later.
- [ ] Evaluate read replica later.

## Validation

- Reliability changes are backed by monitoring, not guesswork.
- Added complexity has a documented runbook.
- Backups and restore tests remain the primary safety net.
