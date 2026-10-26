#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/postgresql/kagent"

if [[ -t 0 ]]; then
  printf 'Refusing to read a value from an interactive command argument. Pipe it through stdin instead.\n' >&2
  printf 'Example: pass show <entry> | %s\n' "$0" >&2
  exit 1
fi

value=""
IFS= read -r value || [[ -n "$value" ]]
if [[ -z "$value" ]]; then
  printf 'Refusing to store an empty value.\n' >&2
  exit 1
fi

printf '%s' "$value" | vault kv put -mount=homelab/kv "$secret_path" password=- >/dev/null
unset value

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Helios PostgreSQL password for the kagent database owner" \
  -custom-metadata=origin=helios-postgres \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="database=kagent;user=kagent" \
  -custom-metadata=runbook="homelab-k8s plans/0020-kagent-sre-agent.md" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing the value.\n' "$secret_path"
