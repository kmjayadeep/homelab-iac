#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/deepseek/litellm"

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
  -custom-metadata=description="DeepSeek platform API key used by the LiteLLM proxy" \
  -custom-metadata=origin=deepseek \
  -custom-metadata=owner=homelab \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="deepseek-api-chat-completions" \
  -custom-metadata=origin-url="https://platform.deepseek.com/api_keys" \
  -custom-metadata=runbook="homelab-k8s plans/0019-kagent-deployment.md" \
  "$secret_path" >/dev/null

printf 'Imported the DeepSeek key and metadata without printing its value.\n'
