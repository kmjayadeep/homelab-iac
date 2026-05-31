# Todo Index

Platform improvement plans and current status.

## Helios Postgres Platform

| Phase | Status | Document |
| --- | --- | --- |
| 0 | Done | [00-postgres-service-contract.md](00-postgres-service-contract.md) |
| 1 | Done | [01-postgres-backup-correctness.md](01-postgres-backup-correctness.md) |
| 2 | Done | [02-postgres-admin-interface.md](02-postgres-admin-interface.md) |
| 3 | Done | [03-postgres-database-catalog.md](03-postgres-database-catalog.md) |
| 4 | Not started | [04-postgres-monitoring-alerting.md](04-postgres-monitoring-alerting.md) |
| 5 | Not started | [05-postgres-backup-health-restore-automation.md](05-postgres-backup-health-restore-automation.md) |
| 6 | Not started | [06-postgres-security-access.md](06-postgres-security-access.md) |
| 7 | Not started | [07-postgres-reliability-upgrades.md](07-postgres-reliability-upgrades.md) |

## Status legend

- `Not started` - planned but no implementation yet.
- `In progress` - implementation or documentation has begun.
- `Blocked` - waiting on a decision, dependency, or manual inventory.
- `Done` - implemented and validated.

## Current priority

Phase 3 is complete. Next priority is Phase 4:

1. Locate and tune Postgres monitoring and alerting rules.
2. Add backup freshness and synthetic checks.
