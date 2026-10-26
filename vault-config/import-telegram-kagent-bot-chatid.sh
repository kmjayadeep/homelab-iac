#!/usr/bin/env bash
set +x
set -euo pipefail

secret_path="services/telegram/kagent-bot"

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

# Adds/updates the chat_id property next to the token without replacing it.
printf '%s' "$value" | vault kv patch -mount=homelab/kv "$secret_path" chat_id=- >/dev/null
unset value

printf 'Patched chat_id on %s without printing the value.\n' "$secret_path"
