# Vault KV path design

The KV v2 mount is `homelab/kv`. Paths below are logical paths as used by the
Vault CLI and External Secrets; policies add the KV v2 `data/` and `metadata/`
segments internally.

## Rules

1. Name a secret by its owner or issuing system, not by where it is consumed.
2. Reuse one path from multiple policies when consumers intentionally use the
   same credential. Do not copy a value merely to create Kubernetes-specific
   and VM-specific paths.
3. Keep independently rotated or differently scoped credentials in separate KV
   documents under the same owner prefix. For example,
   `services/cloudflare/read-only` and `services/cloudflare/dns-cboxlab` are
   valid distinct identities even if some consumers could technically share a
   token.
4. Similar key names do not imply that credentials are the same. Limited
   duplication is acceptable when it reduces scope or blast radius; accidental
   copies of one credential are not.
5. Use lowercase path components with hyphens. Properties should use stable,
   descriptive names; External Secrets maps them to the key names expected by
   each Kubernetes workload.
6. Store components such as database username and password once. Construct
   consumer-specific values such as connection URLs in the ExternalSecret
   target template or in application configuration.

## Custom metadata

Use KV v2 custom metadata for operational context. Metadata is internal but not
secret: never put tokens, passwords, private identifiers, or credential content
in it.

Required keys:

| Key | Meaning | Format/example |
|---|---|---|
| `description` | Short human-readable purpose | `DNS automation for cboxlab.com` |
| `origin` | System that issued the credential | `cloudflare` |
| `owner` | Accountable application, service, or operator group | `homelab` |
| `managed-by` | How the upstream credential is administered | `manual`, `terraform`, or an operator name |
| `last-rotated-at` | When the upstream credential was last replaced | ISO 8601 date (`YYYY-MM-DD`) or RFC 3339 UTC timestamp |

Optional keys:

| Key | Meaning |
|---|---|
| `expires-at` | Upstream expiry as an ISO 8601 date (`YYYY-MM-DD`), or RFC 3339 UTC timestamp when time matters; omit when it does not expire |
| `rotation-due-at` | Planned rotation as an ISO 8601 date or RFC 3339 UTC timestamp |
| `scope` | Concise non-secret permission summary |
| `external-id` | Non-secret identifier used to locate/revoke the upstream credential |
| `origin-url` | Administrative URL for the issuing system; never include embedded credentials or sensitive query parameters |
| `runbook` | Internal documentation reference for rotation and validation |

Do not record consumers in custom metadata because that list becomes stale;
Vault policies and Git declarations are the source of truth for consumers.
Vault automatically tracks KV version creation times, so a separate `created-at`
field is unnecessary.

Example:

```bash
vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="DNS automation for cboxlab.com" \
  -custom-metadata=origin=cloudflare \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at=2026-08-29T00:00:00Z \
  -custom-metadata=scope="zone:cboxlab.com;zone-read;dns-edit" \
  services/cloudflare/dns-cboxlab
```

## Top-level paths

| Prefix | Purpose | Example |
|---|---|---|
| `apps/<app>/<set>` | Secrets owned and rotated with an application | `apps/litellm/core` |
| `services/<service>/<identity>` | Credentials issued by another service, usable by any authorized consumer | `services/postgresql/litellm` |
| `platform/<component>/<set>` | Homelab operational configuration containing secret material | `platform/monitoring/alertmanager` |

There is deliberately no `shared/` prefix. Intentional sharing is represented
by granting multiple narrowly scoped policies access to the same owner-based
path. Separate scoped identities stay grouped under their owner prefix.
Kubernetes namespaces are authentication constraints only and never appear in
KV paths. Vault Enterprise namespaces are not used.

## Migration map

This map is based on the current application and infrastructure Secrets. It
lists property names only, never values.

| Current Kubernetes Secret | Proposed logical Vault path | Properties / treatment |
|---|---|---|
| `actions-runner-secret` | `services/github/actions-runner` | `token`; reuse this path outside Kubernetes only if it is the same GitHub identity |
| `baskit-metrics-firebase` and the Firebase item in `baskit-backup` | `services/firebase/baskit` | `service_account_json`; these look duplicated and should be verified before consolidating |
| `baskit-backup` object-storage fields | `services/minio/baskit-backup` | `endpoint`, `bucket`, `access_key`, `secret_key`, `use_tls`; keep `GCP_PROJECT_ID` as non-secret configuration |
| `ghcr-secret` | `services/ghcr/baskit-pull` | canonical registry credentials; ESO renders `.dockerconfigjson` |
| `fava-auth` | `apps/beancount/auth` | `auth` |
| `dotbintask-secret` | `apps/dotbintask/api` | `tokens` |
| `glance-secret` AdGuard item | `services/adguard/glance` | `password` or token issued for Glance |
| `glance-secret` Immich item | `services/immich/glance` | `api_key` issued for Glance |
| `litellm-secrets` application keys | `apps/litellm/core` | `master_key`, `salt_key` |
| `litellm-secrets` database item | `services/postgresql/litellm` | canonical connection components; render `DATABASE_URL` for Kubernetes |
| `otpcloud-secret` application item | `apps/otpcloud/core` | `app_key` |
| `otpcloud-secret` database item | `services/postgresql/otpcloud` | canonical connection components; render `DB_CONNECTION_STRING` |
| `psuite-wiki-creds` | `apps/psuite/wiki` | `creds` |
| `psuite-restic-creds` | `services/object-storage/psuite-restic` | repository, access key, secret key, and Restic password |
| `shoppinglist-config` | `services/postgresql/shoppinglist` | username/password/database/host; render the application's `POSTGRES_PASSWORD` and URL |
| `taskplanner-config` | `services/postgresql/taskplanner` | username/password/database/host; render the application's `POSTGRES_PASSWORD` and URL |
| `openvpn-config` | `services/vpn/deluge-openvpn` | authentication and client configuration documents |
| `wg-config` | `services/vpn/deluge-wireguard` | WireGuard configuration document |
| `wallabag-config` | `apps/wallabag/core` | Symfony application secret |
| cert-manager and external-dns Cloudflare Secrets | `services/cloudflare/dns-cboxlab` | `api_token`; both consumers intentionally share this zone-scoped identity; future identities remain under `services/cloudflare/` |
| `grafana-creds` | `platform/monitoring/grafana-admin` | admin username and password |
| `alertmanager-config` | `platform/monitoring/alertmanager` | configuration document; split receiver credentials later when supported cleanly |
| `loki-minio-creds` | `services/object-storage/loki` | access key and secret key |
| `thanos-s3` | `services/object-storage/thanos` | object-store connection components; ESO may render `objstore.yml` |
| `restic-config` | `platform/backup/restic-exporter` | configuration document; split backend identities into `services/object-storage/...` when practical |

Inventory issues to resolve during migration:

- `k8s-ai-sre` references `k8s-ai-sre-env`, but no Secret declaration exists in
  the repository. Identify its owner and properties before assigning a path.
- `psuite-restic-creds` exists as a plaintext manifest but is not included by the
  psuite Kustomization and is not referenced by its workloads. Confirm whether
  it is active before migrating it.
- Matching property names do not prove matching values. In particular, verify
  the Firebase and Cloudflare candidates securely without printing values or
  placing them in migration scripts.

The wildcard TLS Secret `cosmos-cboxlab-cert` is generated by cert-manager and
is not migrated to Vault/ESO. Keeping certificate issuance outside ESO avoids a
Vault/ingress bootstrap cycle.

## Example consumer policy input

A Kubernetes workload can read multiple owner-based paths without combining or
duplicating their values:

```hcl
external_secrets_roles = {
  litellm = {
    kubernetes_namespace = "litellm"
    secret_paths = [
      "apps/litellm/core",
      "services/postgresql/litellm",
    ]
  }
}
```

A VM receives a separate policy and authenticates through its own Vault auth
method, but that policy names the same logical paths. Access is shared; secret
storage is not duplicated.
