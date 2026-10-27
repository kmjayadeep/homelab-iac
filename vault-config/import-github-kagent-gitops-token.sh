#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/github/kagent-gitops"

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
  -custom-metadata=description="GitHub token for the kagent GitOps agent (homelab-k8s contents and pull requests)" \
  -custom-metadata=origin=github \
  -custom-metadata=owner=kagent \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="repo=kmjayadeep/homelab-k8s;contents=rw;pull-requests=rw" \
  -custom-metadata=runbook="homelab-k8s plans/0021-kagent-gitops-agent.md" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing the value.\n' "$secret_path"
