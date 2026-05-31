# Phase 0: Postgres Service Contract

Status: Done

## Goal

Define what the Helios Postgres service promises to apps and what it explicitly does not promise. This makes Postgres feel like a small internal product instead of an ad-hoc VM.

## Current state

- Host: `helios`
- IP: `192.168.1.77`
- Platform: NixOS VM on Proxmox
- Service: PostgreSQL 16
- Extensions: `pgvector` available
- Backup: hourly Restic-backed dump job to Cloudflare R2
- HA: none; single VM

## Decisions made

- Stable app endpoint should be DNS-based: `postgres.cosmos.cboxlab.com:5432`.
- Clients should not depend on the Helios VM IP.
- Access scope is LAN only.
- TLS is not implemented yet, but should be considered as a future improvement.
- `immich` and `uptimekuma` are the most important current databases.
- Other current databases are supported while present, but may be cleaned up later.
- Availability target should be real and monitorable: 99% monthly, excluding planned maintenance.
- Maintenance may happen any time.
- Credentials are delivered manually for now; Vault can be evaluated later.
- Onboarding should move toward an admin interface plus inventory, while keeping infrastructure-as-code as the source of truth.
- Extensions are enabled as needed; only `pgvector` is required right now for Immich.

## Proposed service contract

```text
Service: Helios Postgres
Audience: homelab applications
Availability target: 99% monthly, excluding planned maintenance
RPO: <= 1 hour for databases marked backup=true
RTO: best effort, target < 4 hours for normal restore
HA: no automatic failover
Backups: hourly logical dumps, encrypted Restic repository in Cloudflare R2
Restore tests: monthly or quarterly target
```

## Deliverables

- [x] Create a user-facing service document at `docs/platform/postgres.md`.
- [x] Document endpoint, version, extensions, and onboarding process.
- [x] Document backup policy, RPO, RTO, and restore expectations.
- [x] Document known limitations: single VM, no automatic failover, homelab-grade SLA.
- [x] Update `inventory/platform.yml` with agreed RPO/RTO details.

Deferred to Phase 5:

- [ ] Update `inventory/backups.md` after restore testing begins.

## Validation

- The service contract is readable without inspecting Nix or Terraform.
- A new app can understand how to request/connect to a DB.
- Backup and restore expectations are explicit.
