#!/usr/bin/env bash
set +x
set -euo pipefail

postgres_path="services/postgresql/bookorbit"
app_path="apps/bookorbit/core"

if [[ -t 0 ]]; then
  printf 'Refusing to read secrets from command arguments. Pipe the PostgreSQL password, JWT secret, and setup token (one per line) through stdin.\n' >&2
  exit 1
fi

umask 077
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

IFS= read -r postgres_password || [[ -n "$postgres_password" ]]
IFS= read -r jwt_secret || [[ -n "$jwt_secret" ]]
IFS= read -r setup_bootstrap_token || [[ -n "$setup_bootstrap_token" ]]

for secret_name in postgres_password jwt_secret setup_bootstrap_token; do
  if [[ -z "${!secret_name}" ]]; then
    printf 'Refusing to store an empty %s.\n' "$secret_name" >&2
    exit 1
  fi
done

printf '%s' "$postgres_password" >"$work_dir/postgres_password"
printf '%s' "$jwt_secret" >"$work_dir/jwt_secret"
printf '%s' "$setup_bootstrap_token" >"$work_dir/setup_bootstrap_token"
unset postgres_password jwt_secret setup_bootstrap_token

vault kv put -mount=homelab/kv "$postgres_path" \
  password=@"$work_dir/postgres_password" >/dev/null
vault kv put -mount=homelab/kv "$app_path" \
  jwt_secret=@"$work_dir/jwt_secret" \
  setup_bootstrap_token=@"$work_dir/setup_bootstrap_token" >/dev/null

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="BookOrbit PostgreSQL role credential" \
  -custom-metadata=origin=postgresql \
  -custom-metadata=owner=bookorbit \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="database:bookorbit;role:bookorbit" \
  "$postgres_path" >/dev/null
vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="BookOrbit application signing and setup credentials" \
  -custom-metadata=origin=bookorbit \
  -custom-metadata=owner=bookorbit \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  "$app_path" >/dev/null

printf 'Imported BookOrbit secrets and metadata without printing their values. Set the Helios bookorbit role to the same PostgreSQL password before deploying the application.\n'
