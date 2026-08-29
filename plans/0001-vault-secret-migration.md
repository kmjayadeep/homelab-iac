# Plan 0001: Incremental Vault secret migration

- Status: Proposed
- Related ADR: `homelab-k8s/adrs/0001-vault-external-secrets.md`
- Kubernetes rollout plan: `homelab-k8s/plans/0001-sealed-secrets-to-vault.md`

## Goal

Move canonical secret values to the existing `homelab/kv` KV v2 mount without
creating consumer-specific copies for Kubernetes and non-Kubernetes platforms.
Distinct scoped identities may use separate documents under the same service
prefix when that reduces permissions or blast radius. This repository manages
mounts, auth methods, policies, and roles only. Values are written with
a secure operator workflow and never through Terraform, Git, command arguments,
or plan output.

The path taxonomy and current-secret mapping are in
`vault-config/PATHS.md`.

## Migration contract

Each migration unit follows the same order:

1. Confirm the owner, consumers, properties, and rotation boundary.
2. Create one canonical KV document through a secure interactive workflow.
3. Add exact-path policies for every consumer identity. A VM and Kubernetes may
   have separate auth roles that read the same path.
4. Apply Terraform and test authentication without reading values into logs.
5. Let the Kubernetes repository create a parallel `*-vault` Secret and cut the
   consumer over.
6. Observe at least one normal reconciliation or scheduled execution.
7. Rotate the upstream credential when practical, then verify all authorized
   consumers and revoke the old credential.
8. Only after Kubernetes validation, remove the old SealedSecret in the
   Kubernetes repository as a separate change.

A phase is complete only when backup/restore impact is understood and rollback
has been tested. Rollback changes the consumer back to its old Kubernetes Secret;
it does not delete the new Vault value.

## Phase 0: Foundation and non-production authentication test

**Impact:** prerequisite; no production secret changes.

- [ ] Configure trusted internal TLS for Vault and record the CA reference ESO
  will use. Do not use the public ingress as the steady-state in-cluster path.
- [ ] Verify Vault Raft backup, restore, seal, and unseal procedures.
- [ ] Apply the Kubernetes auth backend from `vault-config/auth.tf`.
- [ ] Confirm Vault's ServiceAccount can perform Kubernetes TokenReview.
- [ ] Apply a temporary canary role and non-sensitive test KV document.
- [ ] Validate login from a dedicated ServiceAccount and denial of an unrelated
  path, then remove the canary document and role.
- [ ] Establish a short-lived/scoped Terraform administration identity to
  replace routine root-token use when feasible.

## Phase 1: Cloudflare DNS token

**Priority:** first. It is duplicated across cert-manager and external-dns and is
painful to rotate safely. DNS and certificate issuance are high impact, so this
phase must not be combined with another migration.

Canonical path:

```text
services/cloudflare/dns-cboxlab
```

- [ ] Create one token restricted to DNS editing and zone reading for
  `cboxlab.com`. cert-manager and external-dns intentionally share this identity
  because they require the same zone permissions.
- [ ] Store property `api_token` once and add the required custom metadata from
  `vault-config/PATHS.md`.
- [ ] Add separate Vault Kubernetes roles for the `cert-manager` and
  `external-dns` namespaces. Both roles read only this exact path.
- [ ] Add future Cloudflare identities, such as read-only or another zone, as
  sibling documents under `services/cloudflare/`.
- [ ] After Kubernetes cutover, issue a fresh Cloudflare token, update the one
  Vault property, validate DNS updates and a test certificate issuance, and
  revoke the old token.

## Phase 2: Evidently duplicated and high-toil integrations

**Impact:** high rotation benefit; limited application blast radius. Migrate one
credential family per change.

1. **Baskit Firebase** — `services/firebase/baskit`
   - Securely verify whether backup and metrics currently use the same service
     account.
   - If identical, store one `service_account_json` and authorize both Baskit
     roles. If not, retain separate identity paths.
2. **GitHub Actions runner** — `services/github/actions-runner`
   - Preserve only the permissions required by ARC.
   - Rotate after cutover because the current token has long-lived ciphertext
     history.
3. **GHCR pull identity** — `services/ghcr/baskit-pull`
   - Store canonical registry fields and render `.dockerconfigjson` in ESO.
   - Other Kubernetes namespaces or VMs may use the path only if they use the
     same registry identity.
4. **Glance integrations** — `services/adguard/glance` and
   `services/immich/glance`
   - Keep these as separate issuing systems and rotation boundaries.

## Phase 3: Isolated application-owned secrets

**Impact:** low cross-service impact and straightforward rollback. Migrate one
application at a time in this order:

1. `apps/beancount/auth`
2. `apps/dotbintask/api`
3. `apps/psuite/wiki`
4. `apps/wallabag/core`
5. `apps/otpcloud/core`
6. `apps/litellm/core`

Each Kubernetes role receives only its application's exact path. Do not place
external database credentials in these documents.

## Phase 4: PostgreSQL identities

**Impact:** coordinated application restart and possible outage. Complete only
with a database rollback procedure.

Paths:

```text
services/postgresql/shoppinglist
services/postgresql/taskplanner
services/postgresql/otpcloud
services/postgresql/litellm
```

- [ ] Store canonical components such as host, port, database, username, and
  password once; do not also store a connection URL.
- [ ] Have ESO or application configuration render `DATABASE_URL` or
  `DB_CONNECTION_STRING` as required.
- [ ] Migrate shoppinglist and taskplanner first because their current manifests
  expose a simple password-to-URL construction.
- [ ] Migrate otpcloud and litellm separately after validating their connection
  string formats and restart behavior.
- [ ] Rotate one database role at a time and retain a tested rollback role until
  the observation window closes.

## Phase 5: Object storage and backup credentials

**Impact:** high durability risk. A successful job is insufficient; verify a
restore/read path before deleting old Secrets.

1. `services/object-storage/baskit-backup`
2. `services/object-storage/loki`
3. `services/object-storage/thanos`
4. `platform/backup/restic-exporter`
5. `services/object-storage/psuite-restic` only if confirmed active

- [ ] Use separate object-store identities and least-privilege bucket policies
  unless credentials are intentionally identical.
- [ ] Render application-specific files such as `objstore.yml` from canonical
  fields rather than storing duplicate component and file forms.
- [ ] Run and verify a Baskit backup restore, a Loki query over historical data,
  a Thanos historical query, and a Restic integrity/restore check as applicable.

## Phase 6: VPN client material

**Impact:** network outage for the torrent client; configuration is file-shaped
and harder to inspect automatically.

- `services/vpn/deluge-openvpn`
- `services/vpn/deluge-wireguard`

Migrate one VPN method at a time. Verify tunnel establishment, expected egress
address, DNS behavior, and kill-switch behavior before removing its old
SealedSecret.

## Phase 7: Monitoring operational configuration

**Impact:** can hide failures during later work, so migrate last.

- `platform/monitoring/grafana-admin`
- `platform/monitoring/alertmanager`

Migrate Grafana first. For Alertmanager, retain the complete secret-bearing
configuration document initially; split receiver credentials only when the
rendering and reload path can be tested without exposing values.

## Exceptions and unresolved inventory

- The cert-manager-generated `cosmos-cboxlab-cert` remains outside Vault/ESO.
- Vault recovery keys, unseal material, and initial root token remain offline.
- `k8s-ai-sre-env` has no declaration in the Kubernetes repository; identify its
owner and source before adding a Vault path.
- `psuite-restic-creds` is not currently included or referenced; do not migrate
it until its use is confirmed.

## Completion criteria

- No active application or infrastructure SealedSecret remains except an
explicitly documented bootstrap exception.
- Every Vault role grants exact paths only.
- Intentionally shared credentials exist once and have multiple consumer
  policies; independently scoped identities are separate under one owner prefix.
- Each migrated credential has a tested rotation procedure.
- Old upstream credentials are revoked after the rollback window.
