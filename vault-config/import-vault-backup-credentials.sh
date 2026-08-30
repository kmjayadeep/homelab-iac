#!/usr/bin/env bash
set -euo pipefail

infra_dir="${1:-../../homelab-infra/geneva/truenas}"
secret_path="services/object-storage/vault-backup"

umask 077
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
mkfifo "$work_dir/access_key" "$work_dir/secret_key"

terraform -chdir="$infra_dir" output -raw vault_backup_access_key >"$work_dir/access_key" &
access_pid=$!
terraform -chdir="$infra_dir" output -raw vault_backup_secret_key >"$work_dir/secret_key" &
secret_pid=$!

vault kv put -mount=homelab/kv "$secret_path" \
  endpoint="https://minio.cosmos.cboxlab.com" \
  bucket="vault-cosmos-backups" \
  region="us-east-1" \
  access_key=@"$work_dir/access_key" \
  secret_key=@"$work_dir/secret_key" >/dev/null

wait "$access_pid"
wait "$secret_pid"

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Vault Raft snapshots in the dedicated MinIO bucket" \
  -custom-metadata=origin=minio \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=terraform \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="bucket:vault-cosmos-backups;list;read;write" \
  "$secret_path" >/dev/null

printf 'Imported Vault backup credentials and metadata without printing their values.\n'
