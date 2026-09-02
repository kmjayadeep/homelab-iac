# MinIO

Terraform root for the MinIO object-storage service running on TrueNAS.

This root manages buckets, IAM users, policies, service accounts, and bucket
lifecycle rules. It does not manage the TrueNAS host, storage pools, datasets,
shares, or container runtime.

## Credentials

The MinIO administration credentials are loaded from `pass` by `.envrc`.
Terraform state and state backups are encrypted with `git-crypt`.

Do not print Terraform outputs or commit unencrypted state. Generated service
account credentials must be transferred through non-logging workflows such as
`vault-config/import-vault-backup-credentials.sh`.

## Bucket inventory

All buckets in this root have Terraform destruction protection. Removing a
bucket requires an explicit lifecycle change and a separately reviewed data
retention decision.

| Bucket | Owner | Purpose | Lifecycle |
| --- | --- | --- | --- |
| `loki-cosmos-chunks` | Monitoring / Loki | Loki log chunks and indexes | Active; seven-day application retention |
| `loki-cosmos-ruler` | Monitoring / Loki | Loki ruler state | Active |
| `loki-cosmos-admin` | Monitoring / Loki | Loki administrative object state | Active |
| `thanos-cosmos` | Monitoring / Thanos | Long-term Prometheus block storage | Active |
| `nuc-backup` | Homelab backup / NUC | Primary NUC Restic repository and Backrest access | Active |
| `nuc-private-backup` | Homelab backup / NUC | Private NUC Restic repository | Active |
| `vault-cosmos-backups` | Platform / Vault | Vault Raft snapshots | Active; Terraform expiration rules apply |
| `valheim-backup` | Homelab games archive | Legacy Valheim Restic repository | Cold archive; retain until an explicit restore/export and deletion review |

The legacy `valheim-backup` bucket is deliberately retained. It had no writes
after 2024-11-19 when checked during migration, but its data must not be
deleted merely because newer Valheim hosts use per-host repositories.

## Credential mapping

Credential comparisons are performed without printing values.

| Consumer | Effective Terraform identity | Status |
| --- | --- | --- |
| Loki | `minio_iam_service_account.loki` | Vault values match Terraform state |
| Vault snapshot backup | `minio_iam_service_account.vault_backup` | Vault values match Terraform state |
| Backrest | `minio_iam_service_account.backrest-nuc-restic` | Runtime config matches and targets `nuc-backup` only |
| Restic exporter | `minio_iam_service_account.nuc-restic` | Vault config matches this identity, not `monitoring-restic`; reads both NUC repositories |
| Thanos | Unmanaged existing credential | Bucket is `thanos-cosmos`, but live Vault credentials do not match any value in this Terraform state |

Do not remove `monitoring-restic`, `thanos-restic`, or the unmanaged Thanos
credential based only on this inventory. Moving the restic exporter to its
read-only monitoring identity and bringing the effective Thanos identity under
management require separate credential rotations.

## Commands

```bash
direnv allow
terraform init
terraform plan
terraform apply
```

Review the full plan before applying. This is the authoritative Terraform root
for the service. The previous root at `homelab-infra/geneva/truenas` is
retired; do not run Terraform from it.
