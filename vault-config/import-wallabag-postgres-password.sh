#!/usr/bin/env bash
set +x
set -euo pipefail

postgres_path="services/postgresql/wallabag"

if [[ -t 0 ]]; then
  printf 'Refusing to read a secret from command arguments. Pipe the Wallabag PostgreSQL password through stdin.\n' >&2
  exit 1
fi

umask 077
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

IFS= read -r postgres_password || [[ -n "$postgres_password" ]]
if [[ -z "$postgres_password" ]]; then
  printf 'Refusing to store an empty PostgreSQL password.\n' >&2
  exit 1
fi

printf '%s' "$postgres_password" >"$work_dir/postgres_password"
unset postgres_password

vault kv put -mount=homelab/kv "$postgres_path" \
  password=@"$work_dir/postgres_password" >/dev/null

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Wallabag PostgreSQL role credential" \
  -custom-metadata=origin=postgresql \
  -custom-metadata=owner=wallabag \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="database:wallabag;role:wallabag" \
  "$postgres_path" >/dev/null

printf 'Imported the Wallabag PostgreSQL credential and metadata without printing its value. Set the Helios wallabag role to the same password before deployment.\n'
