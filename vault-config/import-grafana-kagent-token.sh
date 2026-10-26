#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/grafana/kagent"

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
  -custom-metadata=description="Grafana Viewer service-account token for the kagent Grafana MCP server" \
  -custom-metadata=origin=grafana \
  -custom-metadata=owner=monitoring \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="grafana-service-account;role=Viewer" \
  -custom-metadata=runbook="homelab-k8s plans/0020-kagent-sre-agent.md" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing the value.\n' "$secret_path"
