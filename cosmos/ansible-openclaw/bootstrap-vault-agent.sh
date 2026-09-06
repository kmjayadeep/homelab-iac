#!/usr/bin/env bash
set -euo pipefail

host_name="${1:-}"
case "$host_name" in
  openclaw | openclaw-chinnu) ;;
  *)
    printf 'Usage: %s <openclaw|openclaw-chinnu>\n' "$0" >&2
    exit 1
    ;;
esac

role_name="${host_name}-certbot"
role_id=""
secret_id=""

cleanup() {
  unset OPENCLAW_VAULT_ROLE_ID OPENCLAW_VAULT_SECRET_ID || true
  role_id=""
  secret_id=""
}
trap cleanup EXIT

role_id="$(vault read -field=role_id "auth/approle/role/${role_name}/role-id")"
secret_id="$(vault write -field=secret_id -f "auth/approle/role/${role_name}/secret-id")"

if [[ -z "$role_id" || -z "$secret_id" ]]; then
  printf 'Vault did not return a complete AppRole identity.\n' >&2
  exit 1
fi

export OPENCLAW_VAULT_ROLE_ID="$role_id"
export OPENCLAW_VAULT_SECRET_ID="$secret_id"

cd "$(dirname "$0")"
ansible-playbook playbooks/bootstrap-vault-agent.yml --limit "$host_name"

printf 'Bootstrapped the %s Vault Agent identity without printing or persisting its credentials locally.\n' "$host_name"
