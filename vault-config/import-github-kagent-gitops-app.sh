#!/usr/bin/env bash
set +x
set -euo pipefail

# Usage: ./import-github-kagent-gitops-app.sh <app_id> <installation_id> < app-private-key.pem
# The App id and installation id are not secret; the private key is read from stdin only.

secret_path="services/github/kagent-gitops"

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <app_id> <installation_id> < private-key.pem\n' "$0" >&2
  exit 1
fi
if [[ -t 0 ]]; then
  printf 'Refusing to read the private key interactively. Redirect the PEM file to stdin.\n' >&2
  exit 1
fi

app_id="$1"
installation_id="$2"
if ! [[ "$app_id" =~ ^[0-9]+$ && "$installation_id" =~ ^[0-9]+$ ]]; then
  printf 'App id and installation id must be numeric.\n' >&2
  exit 1
fi

# private_key=- takes the whole of stdin, preserving PEM newlines.
vault kv put -mount=homelab/kv "$secret_path" \
  app_id="$app_id" installation_id="$installation_id" private_key=- >/dev/null

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="GitHub App for the kagent GitOps agent: homelab-k8s contents and pull requests" \
  -custom-metadata=origin=github \
  -custom-metadata=owner=kagent \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="github-app;repo=kmjayadeep/homelab-k8s;contents=rw;pull-requests=rw;metadata=r" \
  -custom-metadata=external-id="app_id=$app_id" \
  -custom-metadata=runbook="homelab-k8s plans/0021-kagent-gitops-agent.md" \
  "$secret_path" >/dev/null

printf 'Imported the GitHub App credentials to %s without printing the private key.\n' "$secret_path"
