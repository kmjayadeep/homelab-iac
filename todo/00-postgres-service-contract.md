# Phase 0: Postgres Service Contract

Status: Not started

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

## Decisions to make

- Should the stable app endpoint be IP-based or DNS-based?
  - Current: `192.168.1.77:5432`
  - Candidate: `postgres.cosmos.cboxlab.com`
- Which databases are considered platform-supported?
- Which extensions are allowed by default?
- How should app credentials be delivered?
  - Vault
  - SOPS/secrets file
  - manual handoff for now
- What is the maintenance window policy?

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

- [ ] Create a user-facing service document, probably `docs/platform/postgres.md` or `nixos-images/postgres/README.md` expansion.
- [ ] Document endpoint, version, extensions, and onboarding process.
- [ ] Document backup policy, RPO, RTO, and restore expectations.
- [ ] Document known limitations: single VM, no automatic failover, homelab-grade SLA.
- [ ] Update `inventory/platform.yml` with agreed RPO/RTO details.
- [ ] Update `inventory/backups.md` after restore testing begins.

## Validation

- The service contract is readable without inspecting Nix or Terraform.
- A new app can understand how to request/connect to a DB.
- Backup and restore expectations are explicit.
