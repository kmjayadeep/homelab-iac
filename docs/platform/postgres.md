# Helios Postgres Service Contract

## Summary

Helios Postgres is the shared homelab PostgreSQL platform for LAN applications. Apps should treat it as a black-box database service rather than depending on the VM internals.

## Service identity

| Field | Value |
| --- | --- |
| Service | Helios Postgres |
| Host VM | `helios` |
| Current IP | `192.168.1.77` |
| Canonical endpoint | `postgres.cosmos.cboxlab.com:5432` |
| Network scope | LAN only |
| PostgreSQL version | 16 |
| HA/failover | None; single VM |
| Admin | Jayadeep KM |

Clients should use the DNS endpoint, not the VM IP, once the DNS record is available. The IP is an implementation detail and may change.

## Audience

This service is intended for applications running on the homelab LAN, including VMs, Docker/Dockge workloads, and Kubernetes workloads that can reach the LAN endpoint.

It is not intended to be exposed directly to the public internet.

## Supported databases

Current databases are managed from `nixos-images/postgres/modules/postgres.nix`.

Important platform databases:

- `immich`
- `uptimekuma`

Other current databases are supported while present, but may be cleaned up later:

- `planka`
- `totp`
- `coder`
- `shoppinglist`
- `taskplanner`
- `k3s`

## Extensions

Extensions are enabled as needed. Currently required:

- `pgvector` - required by Immich

Additional extensions should be added intentionally through infrastructure-as-code when an app needs them.

## Availability and maintenance

Availability target:

```text
99% monthly, excluding planned maintenance and upstream homelab dependencies.
```

Maintenance policy:

- Maintenance may happen any time.
- Best effort will be made to avoid unnecessary disruption to important apps.
- The service is homelab-grade: the target is monitorable, but there is no automatic failover.

Known availability limitations:

- Single VM on Proxmox.
- No standby replica.
- No automatic failover.
- Depends on LAN networking, Proxmox host health, and Helios VM health.

## Backups and recovery

Backup policy:

| Field | Target |
| --- | --- |
| Backup mechanism | Logical dumps via `pg_dump`, uploaded with Restic |
| Backup destination | Cloudflare R2 bucket `postgres-cosmos-backup` |
| Frequency | Hourly |
| RPO | <= 1 hour for databases included in backup policy |
| RTO | Best effort, target < 4 hours for normal restore |
| Retention | keep last 10, daily 10, monthly 12 |
| Restore tests | Target monthly or quarterly |

Current backup implementation lives in `nixos-images/postgres/modules/backup.nix`.

Important note: backup coverage must be kept aligned with the database inventory. Phase 1 tracks fixing current drift and adding restore validation.

## Credentials

Credential delivery is manual for now.

Future options to evaluate:

- Vault-backed credential storage and rotation.
- App-specific secret files.
- Kubernetes Secrets for K3s workloads.

Expectations:

- Each app should use its own database user.
- App credentials should not be shared across applications.
- Password rotation should be documented before it is automated.

## Onboarding process

Current preferred onboarding path:

1. Add the database/user through infrastructure-as-code.
2. Rebuild Helios.
3. Create or deliver app credentials manually.
4. Confirm the app can connect through the LAN endpoint.
5. Confirm the database is included in the backup policy or explicitly excluded.
6. Update inventory/docs if the app is important.

Future desired onboarding path:

```bash
just db-onboard <app>
```

The future admin interface should update inventory, apply infrastructure changes, and make backup coverage explicit.

## Client contract

Applications should assume:

- Use DNS endpoint, not IP.
- LAN-only access.
- PostgreSQL 16 compatibility.
- App-specific database and user.
- Hourly backup target for databases marked as backed up.
- No automatic failover.
- Planned maintenance can happen any time.

Applications should not assume:

- Public internet access.
- PostgreSQL TLS is currently available.
- Automatic failover or multi-node HA.
- Unlimited connections/storage.
- Point-in-time recovery, until WAL/PITR is explicitly implemented.

## Future improvements

Tracked in `todo/`:

- DNS record and optional TLS for the Postgres endpoint.
- Backup correctness and restore testing.
- Admin interface for onboarding and restore operations.
- Database catalog/inventory as source of truth.
- Monitoring, alerting, and synthetic checks.
- Optional Vault integration for credentials.
- Optional WAL/PITR or read replica after basics are reliable.
