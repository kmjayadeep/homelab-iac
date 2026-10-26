#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="apps/litellm/kagent"

if [[ -t 0 ]]; then
  printf 'Refusing to read a key from an interactive command argument. Pipe it through stdin instead.\n' >&2
  printf 'Example: pass show <entry> | %s\n' "$0" >&2
  exit 1
fi

api_key=""
IFS= read -r api_key || [[ -n "$api_key" ]]
if [[ -z "$api_key" ]]; then
  printf 'Refusing to store an empty key.\n' >&2
  exit 1
fi

printf '%s' "$api_key" | vault kv put -mount=homelab/kv "$secret_path" api_key=- >/dev/null
unset api_key

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="LiteLLM virtual key restricted to the kagent-default model, used by kagent" \
  -custom-metadata=origin=litellm \
  -custom-metadata=owner=litellm \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="litellm-virtual-key;models=kagent-default" \
  -custom-metadata=runbook="homelab-k8s plans/0019-kagent-deployment.md" \
  "$secret_path" >/dev/null

printf 'Imported the kagent LiteLLM key and metadata without printing its value.\n'
