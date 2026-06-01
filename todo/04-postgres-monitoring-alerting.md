# Phase 4: Monitoring and Alerting

Status: Done

## Goal

Complete the visibility loop: know whether Helios/Postgres is healthy, whether users are affected, and whether backups are fresh.

## Current state

`nixos-images/postgres/modules/monitoring.nix` enables:

- node exporter
- postgres exporter

Prometheus/Grafana/Alertmanager are managed in the Kubernetes GitOps repo:

- `/home/jayadeep/workspace/homelab/homelab-k8s/clusters/titania/infra/monitoring/helmrelease-prometheus.yaml`

That HelmRelease contains `additionalPrometheusRulesMap.postgresql` and the scrape job for Helios.

## Dashboards to have

- Helios CPU, memory, disk, network
- Postgres up/down
- active connections
- max connection usage
- DB size by database
- cache hit ratio by database
- locks and deadlocks
- long-running transactions
- slow or expensive queries if available
- backup freshness and backup failures

## Alerts to have

Important platform alerts:

- `PostgresDown`
- `HeliosDown`
- `PostgresTooManyConnections`
- `PostgresDiskLow`
- `PostgresLongRunningTransaction`
- `PostgresDeadlocks`
- `PostgresBackupFailed`
- `PostgresBackupStale`
- `ResticCheckFailed`

Noisy/needs-tuning alerts:

- `PostgreSQLCacheHitRatio`
  - Tuned in the Kubernetes monitoring repo from `critical` to `warning`.
  - Uses a longer 15m rate window and 30m `for` duration.
  - Remains warning-level because Immich can legitimately do large scans.

## Synthetic checks

Add user-facing checks, not only exporter checks:

```sql
select 1;
```

Possible synthetic targets:

- default `postgres` DB
- `immich`
- `k3s`
- any other critical DB

## Deliverables

- [x] Locate where Prometheus rules for Postgres are managed.
- [x] Add or import Grafana dashboard for Postgres.
- [x] Tune `PostgreSQLCacheHitRatio` severity/threshold.
- [x] Add backup freshness alert.
- [x] Cover backup job failures indirectly through Restic stale-backup monitoring.
- [x] Use `pg_up` as the current query-health check; defer a separate synthetic SQL checker until a tool is chosen.

## Implemented changes

In `homelab-k8s/clusters/titania/infra/monitoring/helmrelease-prometheus.yaml`:

- Scoped `PostgreSQLDown` to `job="helios"` and fixed the description.
- Added `HeliosExporterDown` for scrape target failures.
- Added `PostgreSQLImportantDatabaseMissingMetrics` for missing important DB metrics.
- Tuned `PostgreSQLCacheHitRatio` to warning-level with a longer window.
- Added `PostgreSQLBackupStale` based on Restic exporter metrics for repos matching `.*postgres.*`.

Deferred:

- Direct systemd unit failure alert for `backup-postgres.service`; `node_systemd_unit_state` and other systemd metrics are not currently exposed for Helios. Restic stale-backup monitoring is good enough for now.
- Dedicated blackbox/app-style SQL checks. `pg_up` verifies exporter query health and is good enough for now.

## Validation

- An actual Postgres outage pages/alerts.
- A stale backup pages/alerts.
- Expected Immich behavior does not constantly produce critical noise.
- Dashboard answers: is it up, is it slow, is disk/memory constrained, are backups healthy?
