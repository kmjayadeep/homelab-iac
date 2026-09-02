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
