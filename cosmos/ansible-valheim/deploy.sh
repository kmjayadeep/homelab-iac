#!/usr/bin/env bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <hostname>" >&2
    exit 1
fi

host="$1"

ansible-galaxy collection install -r requirements.yml
ansible "$host" -m ping
ansible-playbook playbooks/setup.yml --limit "$host"

echo "Deployment complete for $host."
echo "Logs: ssh ansible@$host.cosmos.cboxlab.com 'sudo journalctl -u valheim -f'"
