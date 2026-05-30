# Homelab Platform Inventory

This directory is the source of truth for platform-level homelab clarity. The first version is optimized for one question:

> What breaks if this hardware, storage, network, or cloud dependency fails?

The inventory intentionally stays above app workload detail. Individual containers, Kubernetes workloads, cron jobs, and systemd units are only listed when they explain a platform dependency.

## Files

- `platform.yml` - structured inventory for compute, network, storage, VMs, platform services, and backups.
- `index.html` - self-contained interactive failure-impact visualization.
- `failure-impact.mmd` - Mermaid dependency graph for failure blast-radius review.
- `backups.md` - backup-path summary and restore-confidence notes.

## Tier Meaning

Tiers are impact-based, not formal uptime SLAs:

- `P0` - broad foundational impact; failure breaks access, DNS, storage, or many workloads.
- `P1` - important platform/data service; failure breaks multiple important services.
- `P2` - useful single-purpose service or smaller platform component.
- `P3` - best-effort, lab, game, or convenience workload.
- `unknown` - needs assessment.

## Current High-Impact Components

- `truenas` is modeled as `P0` because it backs the `nfs-templates` NFS export, the Docker jail that runs MinIO, MinIO's mounted NAS storage, and NAS replication.
- `mars`, `jupiter`, and the 2.5G switch are `P0` because several platform VMs and TrueNAS depend on that hardware segment.
- `pluto` is modeled separately because it connects directly to the ISP router at 1 Gbps and runs PBS as a backup target for most VMs.
- `gatekeeper` is `P0` because it appears to provide local DNS/proxy functions.
- `router`, `internet`, subnet, and gateway are collapsed into one `ISP router + internet` component in the visual map.
- `helios` is a VM, but Postgres is also modeled as a `P1` platform layer so apps can depend on it as a black box.
- `k3s_titania` is a `P1` platform spanning `titania-master` and `titania-worker1`.

## Maintenance Notes

- Prefer adding `unknown` and `todos` over omitting missing facts.
- Keep secrets out of this inventory. Record secret locations or mechanisms, not secret values.
- When a component moves hosts or gains a backup, update both `platform.yml` and the relevant docs/diagram.
- Use the inventory to decide the next documentation pass: restore runbooks, HA options, or app-level SLAs.
