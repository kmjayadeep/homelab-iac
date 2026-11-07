#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="apps/valheim-vartha/editor"

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

printf '%s' "$value" | vault kv put -mount=homelab/kv "$secret_path" token=- >/dev/null
unset value

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Bearer token the Valheim Vartha dashboard accepts from its AI editor" \
  -custom-metadata=origin=homelab \
  -custom-metadata=owner=valheim \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="valheim-nomap dashboard;POST /api/edition" \
  -custom-metadata=runbook="homelab-k8s clusters/titania/apps/kagent/README.md" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing the value.\n' "$secret_path"
