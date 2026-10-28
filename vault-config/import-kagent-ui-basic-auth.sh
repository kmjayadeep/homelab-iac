#!/usr/bin/env bash
set +x
set -euo pipefail

# Usage: ./import-kagent-ui-basic-auth.sh <username> < password-on-stdin
secret_path="apps/kagent/ui-basic-auth"

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <username> < password\n' "$0" >&2
  exit 1
fi
if [[ -t 0 ]]; then
  printf 'Refusing to read the password interactively. Pipe it through stdin.\n' >&2
  exit 1
fi

username="$1"
password=""
IFS= read -r password || [[ -n "$password" ]]
if [[ -z "$password" ]]; then
  printf 'Refusing to store an empty password.\n' >&2
  exit 1
fi

printf '%s' "$password" | vault kv put -mount=homelab/kv "$secret_path" username="$username" password=- >/dev/null
unset password

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="HTTP basic-auth credential for the kagent UI Ingress" \
  -custom-metadata=origin=kagent \
  -custom-metadata=owner=kagent \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="ingress basic auth; nginx auth-secret rendered by External Secrets" \
  -custom-metadata=runbook="homelab-k8s clusters/titania/apps/kagent/README.md" \
  "$secret_path" >/dev/null

printf 'Imported %s (username %s) without printing the password.\n' "$secret_path" "$username"
