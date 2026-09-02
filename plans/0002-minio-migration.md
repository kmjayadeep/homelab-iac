# MinIO Terraform Migration

## Goal

Move the MinIO Terraform root from `homelab-infra/geneva/truenas` to
`homelab-iac/storage/minio` without changing or recreating any live MinIO
resource.

The source root manages MinIO running on TrueNAS. It does not manage the
TrueNAS host, pools, datasets, shares, or Docker jail itself.

## Safety constraints

- Freeze applies from `homelab-infra/geneva/truenas` during migration.
- Do not delete or recreate buckets, users, policies, service accounts, or
  lifecycle rules as part of the repository move.
- Do not inspect, print, or copy credential values outside the encrypted
  Terraform state and the existing non-logging secret workflows.
- Keep resource addresses and the MinIO provider version unchanged for the
  initial move.
- Treat provider upgrades, resource renames, module adoption, credential
  rotation, and decommissioning as separate follow-up work.

## Phase 1: Consumer inventory

### Terraform state

The source state currently contains 36 resources:

| Resource group | Managed resources | Inventory result |
| --- | ---: | --- |
| Loki | 3 buckets, user, policy, attachment, service account | Active |
| Thanos | bucket, user, policy, attachment, service account | Active |
| Monitoring/restic exporter | user, policy, attachment, service account | Active; currently uses the broader `nuc-restic` identity |
| NUC backups | 2 buckets, user, policy, attachment, service account | Active writes confirmed; runtime producer identity remains unknown |
| Backrest | user, NUC policy attachment, service account | Active; managed identity targets `nuc-backup` only |
| Legacy Valheim | bucket, user, policy, attachment, service account | Retained as a protected cold archive |
| Vault backups | bucket, lifecycle policy, user, policy, attachment, service account | Active |

### Evidence

#### Loki — confirmed active

- `homelab-k8s/clusters/titania/infra/monitoring/helmrelease-loki.yaml`
  names all three managed Loki buckets and the MinIO endpoint.
- `homelab-k8s/clusters/titania/infra/monitoring/external-secrets.yaml`
  obtains the Loki object-storage credentials from Vault path
  `services/object-storage/loki`.
- The live Loki HelmRelease is Ready and its pods are running.
- The `loki-minio-creds-vault` ExternalSecret is Ready.

#### Thanos — confirmed active

- `homelab-k8s/clusters/titania/infra/monitoring/thanos/helm-release.yaml`
  configures Thanos with the `thanos-s3-vault` object-store Secret.
- `homelab-k8s/clusters/titania/infra/monitoring/external-secrets.yaml`
  obtains that configuration from Vault path
  `services/object-storage/thanos`.
- The live Thanos HelmRelease is Ready; query, compactor, and store-gateway
  pods are running.
- The `thanos-s3-vault` ExternalSecret is Ready.

A non-secret comparison confirmed that the Vault-managed object-store
configuration targets `thanos-cosmos`. Its access and secret keys do not match
any credential value in this Terraform state, so the active Thanos credential
is currently unmanaged. Do not remove the Terraform `thanos-restic` account or
the active unmanaged credential until a separate rotation is planned.

#### Monitoring/restic exporter — active, mapping confirmed

- The restic exporter obtains its configuration from Vault path
  `platform/backup/restic-exporter`.
- Its ExternalSecret is Ready and its pod is running.
- The Terraform monitoring policy grants read access to `nuc-backup`,
  `nuc-private-backup`, and `thanos-cosmos`.

A non-printing credential comparison confirmed that the Vault-managed exporter
configuration uses `minio_iam_service_account.nuc-restic`, not the narrower
`monitoring-restic` account. It reads both NUC repositories. Moving it to the
read-only monitoring identity is a separate credential rotation.

#### Backrest — deployment and repository mapping confirmed

- `homelab-docker-stacks/backrest/compose.yaml` defines the Backrest service.
- Its repository configuration is stored in the runtime-mounted
  `/mnt/data/backrest/config`, not in Git.
- Terraform grants the `backrest` service account access to the two NUC
  buckets through `nuc-policy`.

A non-printing comparison against the running Backrest configuration confirmed
that it uses `minio_iam_service_account.backrest-nuc-restic` and references
`nuc-backup`. It does not reference `nuc-private-backup`.

#### NUC backups — active writes confirmed

No tracked consumer outside the old Terraform root names `nuc-backup` or
`nuc-private-backup`. This is expected if backup clients and Backrest are
configured outside Git. A metadata-only MinIO audit found:

| Bucket | Objects | Size | Most recent object timestamp |
| --- | ---: | ---: | --- |
| `nuc-backup` | 2,518 | 42,177,981,126 bytes | 2026-09-02 06:00 UTC |
| `nuc-private-backup` | 205 | 399,829,763 bytes | 2026-09-02 12:00 UTC |

Both buckets are active and must be retained. The audit listed metadata using
the existing Terraform administration account without printing object names
or credential values. Confirm which process writes each bucket and whether
Backrest reads them.

#### Legacy Valheim — retained cold archive

- Current Valheim hosts in Ansible are `valheim-rivers` and `chillyfries`.
- Those hosts have separately managed per-host MinIO buckets in
  `homelab-iac/cosmos/proxmox`.
- Other retained NixOS Valheim hosts also use separately named buckets.
- The generic `valheim-backup` bucket is only referenced by the old Terraform
  root and encrypted legacy configuration.

A metadata-only MinIO audit found 484 objects totaling 5,379,597,767 bytes;
the most recent object timestamp was 2024-11-19 20:30 UTC. The bucket is
classified as a cold archive and retained until an explicit restore/export and
deletion review. Bucket deletion is not part of this work.

#### Vault backups — confirmed active

- `homelab-iac/vault-config/import-vault-backup-credentials.sh` imports this
  service account into Vault path `services/object-storage/vault-backup` using
  a non-logging workflow.
- `homelab-k8s/clusters/titania/apps/vault/backup-external-secret.yaml`
  delivers those credentials to the backup CronJob.
- The ExternalSecret is Ready and the live CronJob reports a recent successful
  run.
- Terraform manages daily, weekly, and monthly expiration rules for the
  bucket.

### Phase 1 decision

Migrate all 36 state resources unchanged, including unresolved and probably
legacy groups. The repository move must not be combined with resource
retirement. Resolve the remaining consumer questions after the state has been
moved and a zero-change plan has been established from the new root.

### Remaining checks

- [x] Confirm the Thanos Vault configuration targets `thanos-cosmos` without
      displaying the configuration or credentials; its active credential is
      not represented in this Terraform state.
- [x] Confirm the restic exporter uses `nuc-restic`, rather than
      `monitoring-restic`, without displaying credentials.
- [x] Inspect non-secret MinIO metadata for object count and most recent write
      time in both NUC buckets.
- [ ] Confirm the process writing each NUC bucket; current object activity and
      the exporter configuration establish that both remain active.
- [x] Confirm the running Backrest repositories use the Terraform-managed
      Backrest account and target `nuc-backup` only.
- [x] Inspect non-secret activity metadata for `valheim-backup`.
- [x] Classify `valheim-backup` as a retained cold archive pending an explicit
      restore/export and deletion review.
- [x] Record an owner and recovery purpose for every retained bucket in
      `storage/minio/README.md`.

## Phase 2: Exact state-preserving move

- [x] Create `storage/minio` in `homelab-iac`.
- [x] Copy tracked Terraform configuration, `.envrc`, provider lock file,
      encrypted state, and encrypted state backup without copying the source
      `.terraform` directory.
- [x] Preserve all 36 resource addresses and MinIO provider version `2.5.0`.
- [x] Preserve state lineage `efcb1bc3-4d22-7593-9a3e-b06df546daea` and serial
      `60`; source and destination state checksums matched immediately after
      copying.
- [x] Verify the destination state and backup pass through the `git-crypt`
      clean filter before staging them.
- [x] Run `terraform init -reconfigure`, `terraform fmt -check`, and
      `terraform validate` successfully.
- [x] Run a refreshed Terraform plan using the existing administration
      credentials without printing credential values.

The installed Terraform CLI is `1.16.0`, so the copied Core constraint was
widened from `~> 1.15.9` to `~> 1.15`. The provider remains pinned to `2.5.0`.
Terraform formatting and output sensitivity changes do not alter resource
addresses.

The plan reported zero resource changes. It reported metadata-only changes for
six outputs because their access keys are now marked sensitive:

- `backrest_nuc_access_key`
- `loki_access_key`
- `monitoring_access_key`
- `nuc_access_key`
- `thanos_access_key`
- `valheim_access_key`

Applying those output metadata changes and proving the new root authoritative
belongs to the ownership cutover phase.

## Phase 3: Ownership cutover

- [x] Update repository documentation and inventory references.
- [x] Point the Vault backup credential import helper at `storage/minio`.
- [x] Mark every credential output sensitive.
- [x] Apply only the six reviewed output-sensitivity metadata changes from the
      new root.
- [x] Confirm the resulting state retains all 36 resources, the original
      lineage, and advances from serial 60 to serial 61.
- [x] Confirm a refreshed post-cutover plan has zero resource and output
      changes.
- [x] Mark the old root retired and leave a pointer to the new location.
- [x] Move the retained old configuration and stale state to
      `homelab-infra/archived/truenas` for migration history and recovery
      reference.

`homelab-iac/storage/minio` is now the authoritative Terraform root. Do not run
Terraform from `homelab-infra/archived/truenas`; its retained state is stale.

## Phase 4: Hardening and provider upgrade

- [x] Add Terraform `prevent_destroy` lifecycle protection to all eight
      buckets managed by this root.
- [x] Document bucket owners, purposes, lifecycle status, and effective
      credential mappings in `storage/minio/README.md`.
- [x] Retain `valheim-backup` as a protected cold archive pending an explicit
      restore/export and deletion review.
- [x] Upgrade the MinIO provider from `2.5.0` to `3.41.0`.
- [x] Configure provider region `us-west-000`, required by the upgraded
      provider for this MinIO deployment.
- [x] Confirm the upgraded provider produces zero resource and output changes.

## Follow-up work

- Identify the process writing each NUC repository.
- Rotate the restic exporter from `nuc-restic` to the read-only
  `monitoring-restic` identity.
- Bring the effective Thanos credential under Terraform management through a
  separately reviewed rotation.
- Decommission unused identities only after consumer checks.
- Keep the MinIO resources in `cosmos/proxmox` independent; cross-state
  consolidation is intentionally out of scope.
