# Phase 4: Monitoring and Alerting

Status: Not started

## Goal

Complete the visibility loop: know whether Helios/Postgres is healthy, whether users are affected, and whether backups are fresh.

## Current state

`nixos-images/postgres/modules/monitoring.nix` enables:

- node exporter
- postgres exporter

The Prometheus/Grafana/Alertmanager configuration was not found in this repo during the initial scan. Alerts are clearly firing from `kube-prometheus-stack`, but rule ownership may live outside this repo or in cluster state.

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
  - Currently firing as `critical` for `datname=immich`.
  - Proposed: downgrade to warning or require supporting symptoms like high disk latency/query latency.

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

- [ ] Locate where Prometheus rules for Postgres are managed.
- [ ] Add or import Grafana dashboard for Postgres.
- [ ] Tune `PostgreSQLCacheHitRatio` severity/threshold.
- [ ] Add backup freshness alert.
- [ ] Add systemd unit failure alerts for `backup-postgres.service` if systemd metrics are scraped.
- [ ] Add a synthetic SQL check.

## Validation

- An actual Postgres outage pages/alerts.
- A stale backup pages/alerts.
- Expected Immich behavior does not constantly produce critical noise.
- Dashboard answers: is it up, is it slow, is disk/memory constrained, are backups healthy?
