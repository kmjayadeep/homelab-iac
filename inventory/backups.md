# Backup Paths

This is a platform-level backup summary. It tracks source, mechanism, target, local/offsite status, and restore confidence. Exact restore runbooks are intentionally deferred until the inventory gaps are closed.

| Source | Mechanism | Destination | Offsite | Confidence | Notes |
| --- | --- | --- | --- | --- | --- |
| `helios` Postgres databases | `pg_dumpall --globals-only` plus per-DB `pg_dump -F c`, then Restic via hourly systemd timer | Cloudflare R2 bucket `postgres-cosmos-backup` | Yes | Medium | Configured to cover `planka`, `totp`, `immich`, `coder`, `shoppinglist`, `uptimekuma`, `taskplanner`, and `k3s`. RPO <= 1 hour; RTO target < 4 hours. Needs deployment and restore test. |
| Valheim worlds | Restic via Ansible and/or NixOS backup timer | MinIO running in a TrueNAS Docker jail, backed by mounted NAS storage | No, unless MinIO/NAS replication covers it | Medium | Active path per host needs confirmation. |
| Windrose data | MinIO bucket is provisioned | MinIO running in a TrueNAS Docker jail, backed by mounted NAS storage | No, unless MinIO/NAS replication covers it | Low | Backup job and restore flow are not yet identified. |
| TrueNAS datasets | Unknown NAS replication/backup jobs | Unknown remote bucket | Yes | Unknown | Needs manual TrueNAS inventory: datasets, snapshots, replication tasks, retention, encryption, and restore tests. |
| Most VMs | Proxmox Backup Server | PBS running on `pluto` | No | Unknown | Pluto is directly connected to the ISP router at 1 Gbps. Need exact VM coverage, retention, prune/verify schedule, and restore tests. |
| K3s cluster state and PVs | Unknown | Unknown | Unknown | Unknown | Need to record etcd/sqlite state backup, manifests, ingress, and persistent volume strategy. |

## Immediate Gaps To Close

- Record the Docker jail name/config and the exact TrueNAS dataset path mounted by MinIO.
- Confirm whether MinIO buckets replicate to a remote bucket.
- Record all TrueNAS snapshot and cloud-sync/replication tasks.
- Add restore test dates for Postgres and at least one game-world backup.
- Record PBS datastore, VM coverage, retention, prune/verify jobs, and restore test dates.
