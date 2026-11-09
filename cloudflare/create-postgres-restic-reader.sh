#!/usr/bin/env bash
# Creates the read-only R2 token used by the Postgres restore drill, stores the
# derived S3 credentials in Vault, then revokes any earlier token of that name.
# Rerun it to rotate. Requires a CLOUDFLARE_API_TOKEN that holds the Account API
# Tokens Write permission, and a Vault login that can write the secret path.
set +x
set -euo pipefail

account_id="de346322c951eb2e500a79df4f02317f"
bucket="postgres-cosmos-backup"
jurisdiction="eu"
token_name="postgres-restic-restore-drill"
permission_group="Workers R2 Storage Bucket Item Read"
secret_path="services/object-storage/postgres-restic"
api="https://api.cloudflare.com/client/v4/accounts/$account_id"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
restic_env="$script_dir/../nixos-images/postgres/secrets/secret-restic.env"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

# The token stays out of curl's arguments by reading its config from a pipe.
cf() {
  local method="$1" path="$2"
  shift 2
  curl --silent --show-error --max-time 30 --request "$method" \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$CLOUDFLARE_API_TOKEN") \
    "$@" "$api$path"
}

require_success() {
  jq -e '.success == true' >/dev/null || fail "Cloudflare API call failed: $1"
}

for tool in curl jq sha256sum vault; do
  command -v "$tool" >/dev/null || fail "Missing required tool: $tool"
done
[[ -n "${CLOUDFLARE_API_TOKEN:-}" ]] || fail "CLOUDFLARE_API_TOKEN is not set."
vault token lookup >/dev/null || fail "Log in to Vault first."
grep -q RESTIC_PASSWORD "$restic_env" 2>/dev/null ||
  fail "Cannot read $restic_env. Is the repository unlocked with git-crypt?"

groups="$(cf GET /tokens/permission_groups --get --data-urlencode "name=$permission_group")"
require_success "list permission groups" <<<"$groups"
group_id="$(jq -r --arg name "$permission_group" \
  'first(.result[] | select(.name == $name) | .id) // empty' <<<"$groups")"
[[ -n "$group_id" ]] || fail "Permission group not found: $permission_group"

body="$(jq -n \
  --arg name "$token_name" \
  --arg group "$group_id" \
  --arg resource "com.cloudflare.edge.r2.bucket.${account_id}_${jurisdiction}_${bucket}" \
  '{name: $name, policies: [{
    effect: "allow",
    permission_groups: [{id: $group}],
    resources: {($resource): "*"}
  }]}')"

created="$(cf POST /tokens --header 'Content-Type: application/json' --data "$body")"
require_success "create token" <<<"$created"
token_id="$(jq -r '.result.id' <<<"$created")"

# Revoke the new token if it never reaches Vault, so a failed run leaves nothing behind.
stored=false
discard_unstored_token() {
  if [[ "$stored" == false ]]; then
    cf DELETE "/tokens/$token_id" >/dev/null ||
      printf 'Could not revoke unstored token %s.\n' "$token_id" >&2
  fi
}
trap discard_unstored_token EXIT

# R2 uses the token ID as the access key and the SHA-256 of its value as the secret key.
secret_key="$(jq -j '.result.value' <<<"$created" | sha256sum | cut -d' ' -f1)"
unset created

# shellcheck disable=SC1090
restic_password="$(source "$restic_env" && printf '%s' "$RESTIC_PASSWORD")"
# shellcheck disable=SC1090
restic_repository="$(source "$restic_env" && printf '%s' "$RESTIC_REPOSITORY")"
[[ -n "$restic_password" && -n "$restic_repository" ]] ||
  fail "$restic_env is missing the Restic password or repository."

# Values reach jq through its environment and Vault through stdin, never arguments.
ACCESS_KEY="$token_id" SECRET_KEY="$secret_key" \
  REPOSITORY="$restic_repository" RESTIC_PW="$restic_password" \
  jq -n '{
    repository: env.REPOSITORY,
    access_key: env.ACCESS_KEY,
    secret_key: env.SECRET_KEY,
    restic_password: env.RESTIC_PW
  }' | vault kv put -mount=homelab/kv "$secret_path" - >/dev/null
stored=true
unset secret_key restic_password restic_repository

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Read-only Restic access to Helios Postgres backups for the restore drill" \
  -custom-metadata=origin=cloudflare \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="bucket:$bucket;object-read;list" \
  -custom-metadata=runbook="cloudflare/create-postgres-restic-reader.sh" \
  "$secret_path" >/dev/null

tokens="$(cf GET /tokens)"
require_success "list tokens" <<<"$tokens"
revoked=0
while IFS= read -r old_id; do
  [[ -n "$old_id" ]] || continue
  cf DELETE "/tokens/$old_id" | require_success "revoke token $old_id"
  revoked=$((revoked + 1))
done < <(jq -r --arg name "$token_name" --arg keep "$token_id" \
  '.result[] | select(.name == $name and .id != $keep) | .id' <<<"$tokens")

printf 'Stored %s without printing its values. Revoked %d earlier token(s).\n' "$secret_path" "$revoked"
