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

Current databases are managed from the catalog at `nixos-images/postgres/modules/postgres-catalog.nix`. The NixOS Postgres and backup modules consume that catalog.

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
| Backup mechanism | `pg_dumpall --globals-only` plus per-database `pg_dump -F c`, uploaded with Restic |
| Backup destination | Cloudflare R2 bucket `postgres-cosmos-backup` |
| Frequency | Hourly |
| RPO | <= 1 hour for databases included in backup policy |
| RTO | Best effort, target < 4 hours for normal restore |
| Retention | keep last 10, daily 10, monthly 12 |
| Restore tests | Target monthly or quarterly |

Current backup implementation lives in `nixos-images/postgres/modules/backup.nix`.

Backup layout in the Restic snapshot:

```text
/var/tmp/postgres-backup/current/
  metadata.json
  globals.sql
  databases/
    planka.dump
    totp.dump
    immich.dump
    coder.dump
    shoppinglist.dump
    uptimekuma.dump
    taskplanner.dump
    k3s.dump
```

`metadata.json` records backup timestamps, host, Postgres version, included databases, retention target, and dump sizes.

Helios also keeps one previous local backup under `/var/tmp/postgres-backup/previous`, but Restic only uploads `/var/tmp/postgres-backup/current`.

## Restore procedures

These examples assume commands are run on Helios as an admin with sudo access.

### List Restic snapshots

```bash
sudo -u postgres bash -lc 'source /etc/restic-env && restic snapshots'
```

### Restore latest backup files to a temporary directory

```bash
sudo rm -rf /var/tmp/postgres-restore
sudo -u postgres bash -lc 'source /etc/restic-env && restic restore latest --target /var/tmp/postgres-restore'
```

The restored files should be under:

```text
/var/tmp/postgres-restore/var/tmp/postgres-backup/current/
```

Set a helper variable for the examples below:

```bash
RESTORE_DIR=/var/tmp/postgres-restore/var/tmp/postgres-backup/current
```

### Restore globals on a fresh server

Only run this on a fresh/replacement server or when you intentionally want to restore roles and global objects.

```bash
sudo -u postgres psql -f "$RESTORE_DIR/globals.sql"
```

### Restore one database to a new database

This is the safest normal restore pattern because it does not overwrite the existing database.

```bash
DB=immich
TARGET_DB=immich_restore
OWNER=immich

sudo -u postgres createdb -O "$OWNER" "$TARGET_DB"
sudo -u postgres pg_restore -d "$TARGET_DB" "$RESTORE_DIR/databases/$DB.dump"
```

After validation, applications can be pointed at the restored database or data can be copied back intentionally.

### Restore one table selectively

List dump contents:

```bash
sudo -u postgres pg_restore -l "$RESTORE_DIR/databases/immich.dump" > /tmp/immich-restore.list
```

Edit `/tmp/immich-restore.list` and keep only the objects you want, then restore into a target database:

```bash
sudo -u postgres pg_restore -d immich_restore -L /tmp/immich-restore.list "$RESTORE_DIR/databases/immich.dump"
```

For a simple table restore, `pg_restore -t` can also be used:

```bash
sudo -u postgres pg_restore -d immich_restore -t some_table "$RESTORE_DIR/databases/immich.dump"
```

### Full logical restore outline

On a fresh Postgres server:

1. Restore `globals.sql`.
2. Create each application database with the expected owner.
3. Run `pg_restore` for each database dump.
4. Validate app connectivity.
5. Re-enable app traffic.

Example:

```bash
sudo -u postgres psql -f "$RESTORE_DIR/globals.sql"

for DB in planka totp immich coder shoppinglist uptimekuma taskplanner k3s; do
  sudo -u postgres createdb -O "$DB" "$DB"
  sudo -u postgres pg_restore -d "$DB" "$RESTORE_DIR/databases/$DB.dump"
done
```

Important note: logical dumps support full and selective restore to the latest successful dump time. They do not provide point-in-time recovery; WAL/PITR is a future improvement.

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

1. Add the database/user metadata to `nixos-images/postgres/modules/postgres-catalog.nix`.
2. Set backup policy, criticality, restore priority, and required extensions.
3. Run `nix flake check` from `nixos-images/postgres/`.
4. Rebuild Helios.
5. Create or deliver app credentials manually.
6. Confirm the app can connect through the LAN endpoint.
7. Confirm the database is included in the backup policy or explicitly excluded.
8. Update inventory/docs if the app is important.

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

## Monitoring and alerting

Prometheus rules for Helios Postgres are managed in the Kubernetes GitOps repository:

```text
homelab-k8s/clusters/titania/infra/monitoring/helmrelease-prometheus.yaml
```

Current alerting direction:

- Postgres exporter down/query failure should be critical.
- Helios exporter scrape failures should be critical.
- Backup stale beyond the hourly RPO should be critical.
- `backup-postgres.service` failure should become critical after systemd metrics are exposed.
- Cache hit ratio is warning-level, not critical, because Immich can legitimately do large scans.

Current metric caveat:

- `node_systemd_unit_state` is not currently exposed for Helios, so backup service failure is covered indirectly through stale Restic snapshot alerts for now.

True synthetic SQL checks are still a future improvement.

## Future improvements

Tracked in `todo/`:

- DNS record and optional TLS for the Postgres endpoint.
- Backup correctness and restore testing.
- Admin interface for onboarding and restore operations.
- Database catalog/inventory as source of truth.
- Monitoring, alerting, and synthetic checks.
- Optional Vault integration for credentials.
- Optional WAL/PITR or read replica after basics are reliable.
