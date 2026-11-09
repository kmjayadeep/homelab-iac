#!/usr/bin/env bash
# Stores S3 credentials for the Postgres restore drill in Vault. Pipe in the
# value of an R2 API token limited to Object Read on postgres-cosmos-backup:
#   pass cloudflare/api-token/r2-read-only | cloudflare/import-postgres-restic-reader.sh
# To rotate, create a new token in the dashboard, rerun this, and delete the old one.
set +x
set -euo pipefail

account_id="de346322c951eb2e500a79df4f02317f"
secret_path="services/object-storage/postgres-restic"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
restic_env="$script_dir/../nixos-images/postgres/secrets/secret-restic.env"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

if [[ -t 0 ]]; then
  fail "Refusing to read a value interactively. Pipe the token through stdin."
fi

token=""
IFS= read -r token || [[ -n "$token" ]]
[[ -n "$token" ]] || fail "Refusing to store an empty value."

for tool in curl jq sha256sum vault; do
  command -v "$tool" >/dev/null || fail "Missing required tool: $tool"
done
vault token lookup >/dev/null || fail "Log in to Vault first."
grep -q RESTIC_PASSWORD "$restic_env" 2>/dev/null ||
  fail "Cannot read $restic_env. Is the repository unlocked with git-crypt?"

# The token stays out of curl's arguments by reading its config from a pipe.
verified="$(curl --silent --show-error --max-time 30 \
  --config <(printf 'header = "Authorization: Bearer %s"\n' "$token") \
  "https://api.cloudflare.com/client/v4/accounts/$account_id/tokens/verify")"
jq -e '.success == true and .result.status == "active"' >/dev/null <<<"$verified" ||
  fail "Cloudflare did not accept the token as active."

# R2 uses the token ID as the access key and the SHA-256 of its value as the secret key.
access_key="$(jq -r '.result.id' <<<"$verified")"
secret_key="$(printf '%s' "$token" | sha256sum | cut -d' ' -f1)"
unset token

# shellcheck disable=SC1090
restic_password="$(source "$restic_env" && printf '%s' "$RESTIC_PASSWORD")"
# shellcheck disable=SC1090
restic_repository="$(source "$restic_env" && printf '%s' "$RESTIC_REPOSITORY")"
[[ -n "$restic_password" && -n "$restic_repository" ]] ||
  fail "$restic_env is missing the Restic password or repository."

# Values reach jq through its environment and Vault through stdin, never arguments.
ACCESS_KEY="$access_key" SECRET_KEY="$secret_key" \
  REPOSITORY="$restic_repository" RESTIC_PW="$restic_password" \
  jq -n '{
    repository: env.REPOSITORY,
    access_key: env.ACCESS_KEY,
    secret_key: env.SECRET_KEY,
    restic_password: env.RESTIC_PW
  }' | vault kv put -mount=homelab/kv "$secret_path" - >/dev/null
unset access_key secret_key restic_password restic_repository

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Read-only Restic access to Helios Postgres backups for the restore drill" \
  -custom-metadata=origin=cloudflare \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="bucket:postgres-cosmos-backup;object-read;list" \
  -custom-metadata=runbook="cloudflare/import-postgres-restic-reader.sh" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing its values.\n' "$secret_path"
