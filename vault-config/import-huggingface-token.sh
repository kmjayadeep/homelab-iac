#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/huggingface/model-serving"

if [[ -t 0 ]]; then
  printf 'Refusing to read a token from an interactive command argument. Pipe it through stdin instead.\n' >&2
  printf 'Example: pass show <entry> | %s\n' "$0" >&2
  exit 1
fi

token=""
IFS= read -r token || [[ -n "$token" ]]
if [[ -z "$token" ]]; then
  printf 'Refusing to store an empty token.\n' >&2
  exit 1
fi

printf '%s' "$token" | vault kv put -mount=homelab/kv "$secret_path" token=- >/dev/null
unset token

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Hugging Face model repository access for model serving" \
  -custom-metadata=origin=huggingface \
  -custom-metadata=owner=llm-serving \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="model-repository-read" \
  "$secret_path" >/dev/null

printf 'Imported the Hugging Face token and metadata without printing its value.\n'
