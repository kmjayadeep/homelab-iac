#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="apps/beancount/git-sync"

if [[ -t 0 ]]; then
  printf 'Refusing to read a key from an interactive terminal. Redirect the private key file to stdin.\n' >&2
  printf 'Example: %s < /dev/shm/fava-ledger-key\n' "$0" >&2
  exit 1
fi

# Passed straight through: an SSH private key must keep its trailing newline.
vault kv put -mount=homelab/kv "$secret_path" ssh_private_key=- >/dev/null

vault kv metadata put -mount=homelab/kv \
  -custom-metadata=description="Read-only GitLab deploy key for the private ledger repository, used by the Fava ledger sidecar" \
  -custom-metadata=origin=gitlab \
  -custom-metadata=owner=beancount \
  -custom-metadata=managed-by=manual \
  -custom-metadata=last-rotated-at="$(date -u +%Y-%m-%d)" \
  -custom-metadata=scope="gitlab-deploy-key;read-only" \
  "$secret_path" >/dev/null

printf 'Imported %s and metadata without printing the value.\n' "$secret_path"
