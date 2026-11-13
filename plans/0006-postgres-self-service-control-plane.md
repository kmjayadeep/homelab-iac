# Plan 0006: Postgres self-service control plane (`pgctl`)

- Status: Proposed
- Date: 2026-11-09
- Supersedes: `todo/02`, `todo/05`, `todo/06` and the replica part of `todo/07`
- Related: `docs/platform/postgres.md`, `vault-config/PATHS.md`
- UI mockup and architecture: <https://claude.ai/artifact/5H49jt8fTWpEt31HpRg5vW>

## Goal

Make Helios Postgres self-service. Every routine operation is one automated
code path, available from a CLI and a web UI, and every change is reflected in
the Nix configuration:

- create and manage databases and their users
- see whether backups work, and act on them
- see database sizes and related properties

## Findings that shape this plan

Measured on Helios on 2026-11-08.

- The server is healthy: no out-of-memory kills in 60 days. 718 of 719 backups
  succeeded in 30 days, and the one failure was stopped by a reboot.
- All 13 dumps read back from R2 and decoded completely through `pg_restore`.
  A restore into a running server has never been recorded.
- `ensureDatabases` and `ensureUsers` run in the Postgres unit's post-start
  script at the pinned nixpkgs, so a catalog change restarts Postgres. The
  restarts on 09-20 and 10-28 match the database rollouts on those days.
- The restore runbook's loop omits `bookorbit`, `kagent`, `litellm`,
  `streakslap` and `wallabag`.
- `restic check` is not scheduled. Pluto (Proxmox Backup Server) is unreachable.
- `LiteLLM_SpendLogs` is 2.4 GB of 3.7 GB. The R2 repository is at 6.1 of the
  10 GiB alert threshold. It reached 137% on 10-26 and backups kept running.
- `metadata.json` is not valid JSON: the `databases` array loses its quotes.
- pgweb has been down since 10-28: it has no ordering on Postgres and no
  restart policy. No alert fired because Helios exposes no systemd metrics.
- `k3s` and `uptimekuma` are marked P1 but have zero tables.
- `coder`, `immich`, `k3s`, `planka`, `streakslap` and `uptimekuma` have no
  password path recorded in `vault-config`.
- `postgres_exporter` runs as `postgres-exporter` but connects as `postgres`,
  so it depends on `local all all trust`.
- nixpkgs is pinned to 2025-05-28 and tracks unstable. Postgres is 16.9.

## Decisions

1. Keep Helios. CloudNativePG is the exit if failover or point-in-time recovery
   becomes a requirement. The Phase 7 hand-built replica is dropped.
2. Build `pgctl`, because no existing tool writes to the Nix configuration.
   It is a single Go binary with an embedded server-rendered UI and no CDN
   assets. The UI and CLI call the same operations.
3. `pgctl` runs on Helios as the `postgres` user and uses the local socket, so
   no superuser login exists on the network.
4. `catalog.json` is the source of truth. `pgctl` edits it and Nix reads it with
   `builtins.fromJSON`.
5. Move all of `nixos-images/postgres/` to a new private repository,
   `homelab-postgres`. `pgctl`'s deploy key is then scoped to that repository.
   VM Terraform and Vault policy stay in `homelab-iac`.
6. Reconcile is additive. It never drops a database or role.

## Non-goals

- HA, automatic failover or point-in-time recovery.
- A SQL console or table browser. pgAdmin can be added later if needed.
- Opening Vault or Kubernetes PRs. `pgctl` prints the snippets for now.
- Managing MongoDB.

## Design

### Catalog

```json
{
  "version": 1,
  "databases": {
    "myapp": {
      "owner": "myapp",
      "state": "active",
      "backup": true,
      "criticality": "P3",
      "restorePriority": "normal",
      "extensions": ["vector"],
      "users": [{ "name": "myapp_ro", "access": "readonly" }],
      "vaultPath": "services/postgresql/myapp"
    }
  },
  "extraUsers": []
}
```

- `vaultPath` defaults to `services/postgresql/<name>`. `totp` overrides it
  with `services/postgresql/otpcloud`.
- `backup: false` requires `backupExcludeReason`.
- Names must match `^[a-z][a-z0-9_]{0,62}$`. Extensions are validated against
  `pg_available_extensions`.

### Where changes land

- Database changes need no rebuild. `pgctl` keeps a clone in `/var/lib/pgctl`
  and commits directly to `main` of `homelab-postgres`.
- The commit happens first. If a later step fails, reconcile can finish the
  work and nothing exists outside the catalog.
- The flake builds the same `catalog.json` into the system. A fresh host
  reconciles from that copy at boot and updates its clone when it can.
- `nixos-rebuild` is needed only for Postgres version, settings and services.
- The UI flags anything live but not in the catalog, with an adopt action, and
  shows the deployed revision against the repository head.

### Operations

| Operation | Behaviour |
| --- | --- |
| `db create` | Commit, create role, database and extensions, set password, test login |
| `db list`, `db show` | Sizes, largest tables, connections, owner, extensions, status |
| `db adopt` | Add an existing live database to the catalog |
| `db retire` | Final tagged dump, block logins, set `state: retired` |
| `db drop` | Separate confirmed step, retired databases only |
| `user add-readonly` | Create `<db>_ro`, store its password in Vault |
| `user rotate` | See the password flow below |
| `user import-password` | Read an existing password on stdin and store it in Vault |
| `backup status`, `backup run` | Status from the job's status file; start the systemd unit |
| `backup check` | Start the `restic check` unit |
| `backup restore` | Restore the latest dump into `<db>_restore`, never in place |
| `reconcile` | Idempotent, additive, runs at boot and on demand |

### Password flow

1. Generate the password in memory and compute the SCRAM verifier in `pgctl`,
   so the cleartext never reaches Postgres or its logs.
2. Open a transaction and run `ALTER ROLE`.
3. Write to Vault with metadata. If that fails, roll back.
4. Commit, then test a login with the new password.

Passwords are never displayed, logged or passed as arguments.

Rotation limit: a role has one password, and ExternalSecrets refresh hourly.
After a rotation an app can fail new connections until its Secret syncs and it
restarts. The UI states this and prints the commands. Automating it is out of
scope.

### Vault access

- New AppRole `pgctl`, following `vault-config/openclaw-certbot.tf`.
- Policy: `create` and `update` on `services/postgresql/*` data and metadata,
  and `read` and `list` on metadata only. `pgctl` can never read a password.
- This is a prefix grant and an exception to the repository's exact-path
  convention. Exact paths would need a Terraform apply for every new database.

### Secrets on Helios

`environment.etc.*.source` files are world-readable in the Nix store, so new
secrets do not use it. `pgctl bootstrap` reads the AppRole secret ID, deploy key
and UI password hash from stdin into `/var/lib/pgctl/secrets` with mode 0400. A
rebuilt host repeats this step.

### UI access and privileges

- `pgctl` binds to `127.0.0.1`. nginx provides TLS and basic auth at the
  internal hostname `pgctl.cosmos.cboxlab.com`, reusing the pgweb setup.
- State-changing requests need a CSRF token. Every operation is logged to the
  journal with who and what, never values.
- A polkit rule lets `postgres` start only the backup and check units.
  `postgres` joins `systemd-journal` to show job logs.

### Restore drill

- Monthly Kubernetes CronJob on `titania-gpu`, using a `pgvector/pgvector:pg16`
  image and a 15 GB `emptyDir`.
- It restores the latest snapshot and every dump into its throwaway server,
  using `restic --no-lock` and a read-only R2 token.
- The backup job records each database's table count and estimated rows in
  `metadata.json`. The drill requires exact table counts and estimated rows
  within 10% for tables over 1000 rows.
- A failing check fails the Job. No Pushgateway is needed:
  `kube_cronjob_status_last_successful_time` drives the alert and the UI.

## Phase 0: Immediate fixes in the current repositories

- [ ] Set LiteLLM spend log retention and confirm the dump shrinks.
- [ ] Give pgweb `after`/`requires` on Postgres and `Restart=on-failure`.
- [ ] Enable the node exporter `systemd` collector and alert on failed units.
- [ ] Fix the runbook so the restore loop follows the dump files present.

Exit: `pgweb` survives a reboot, and a failed test unit raises an alert.

## Phase 1: Prove restore

- [x] Import restic credentials to `services/object-storage/postgres-restic`
      through the stdin workflow, using a new read-only R2 token.
- [x] Add the Vault role and CronJob. Run it once by hand.
- [x] Back up every non-template database except `postgres` unless excluded.
- [x] Make `metadata.json` valid JSON.
- [x] Write `status.json` after each run with snapshot ID, timings and sizes.
- [x] Add a weekly `restic check` timer and move `forget --prune` to daily.
- [x] Alert on a failed check and on a drill older than 35 days.
- [x] Record the first drill's date, snapshot and duration in
      `inventory/backups.md`.

Exit: all 13 databases restore and pass validation. Nothing later starts until
this holds.

## Phase 2: Split the repository and update the platform

- [x] Create private `homelab-postgres`. Extract history with
      `git filter-repo --subdirectory-filter nixos-images/postgres`.
- [x] Add `.gitattributes` and reuse the existing git-crypt key. The key never
      goes on Helios, so sharing it does not widen `pgctl`'s access.
- [x] Prove `nixos-rebuild build` gives the same system as before the move.
- [x] Move `docs/platform/postgres.md`. Update `AGENTS.md`, `inventory/*`,
      `todo/index.md` and the kagent gitops agent prompt.
- [x] Enable Renovate, then remove the directory from `homelab-iac`.
- [x] Take a fresh backup, then move nixpkgs to the current stable channel and
      apply it. Postgres stays on major version 16.

Exit: Helios deploys from the new repository on a current nixpkgs.
Rollback: `nixos-rebuild switch --rollback`. The data directory is compatible
across minor versions.

## Phase 3: Catalog, reconcile and CLI

- [x] Convert the catalog to `catalog.json`, consumed through `fromJSON`.
- [x] Build `pgctl` with `buildGoModule`, with `reconcile` and read-only commands.
- [x] Add a NixOS VM test for reconcile, idempotence and "never drops".
- [x] Run `reconcile` against live and confirm it reports no changes.
- [x] Add the boot reconcile unit and remove `ensure*` and
      `postgresql-extensions`. This needs one Postgres restart.
- [x] Add `db create` and the Vault AppRole. Test with a throwaway database.

Exit: a new database appears with no rebuild and no restart.
Rollback: restore the `ensure*` generation. Roles and databases are unaffected.

## Phase 4: Read-only UI

- [x] Add Databases, Database detail and Backups as in the mockup.
- [x] Add the nginx virtual host, certificate, DNS record and basic auth.
- [x] Add drift flags and deployed revision.

Exit: "are backups working?" can be answered from the UI alone.

Done 2026-11-13 (homelab-postgres #6, homelab-k8s #606). pgctl checks basic auth
itself against a bcrypt hash from `pgctl ui-password`, because nginx cannot
read `/var/lib/pgctl/secrets`. R2 usage and the restore drill come from
Prometheus. While building it, the R2 repository was found at 30 GB: LiteLLM's
spend-log retention made every litellm dump change throughout. Its rows are now
excluded through `backupExcludeTableData` (homelab-postgres #4), and the 27
oversized snapshots were forgotten.

## Phase 5: Write operations

- [ ] Add create, adopt, rotate, add-readonly, retire, drop, back up now, repository
      check and restore to a new database, each covered by the VM test.
- [ ] Use retire on `k3s` and `uptimekuma` as the first real run.
- [ ] Import the six missing passwords with `user import-password`.
- [ ] Remove pgweb, its role, DNS record and the Homer and Glance links.

Exit: a new app is onboarded from the UI, and only the access PRs are manual.

## Phase 6: Hardening

- [ ] Set `runAsLocalSuperUser` on the exporter, then change `local trust` to
      `peer`. Verify the exporter and backups.
- [ ] Add `pg_stat_statements` and slow-query logging, and surface them in the UI.
- [ ] Raise RAM to 4 GB and tune `shared_buffers` and related settings.
- [ ] Enable data checksums with `pg_checksums` in a maintenance window.
- [ ] Fix `PostgreSQLSlowQueries`, which uses `rate()` on a duration.
- [ ] Point the important-database alert at `immich` instead of `uptimekuma`.
- [ ] Decide MongoDB: remove it, or add a backup.

## Risks

- `pgctl` has full control of Postgres behind basic auth. It stays internal,
  and destructive actions need two steps.
- Commit-first means a broken push blocks changes. The UI reports this and
  nothing is half-applied.
- A retired database's final dump must survive `forget`, so it is tagged and the
  retention policy keeps that tag.
- Restore into `<db>_restore` creates temporary drift. The suffix is recognised
  and shown as temporary.
