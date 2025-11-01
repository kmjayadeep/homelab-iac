#!/usr/bin/env bash
# Ultra Simple Nova Deployment

set -e

echo "==============================="
echo "Nova Simple Deployment" 
echo "==============================="

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Error: Ansible is not installed."
    echo "Install: pip install ansible"
    exit 1
fi

echo "Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo "Deploying to nova..."
ansible-playbook playbooks/setup.yml

echo ""
echo "✅ Done!"
echo ""
echo "Access: https://nova.hetzner.cboxlab.com"
echo "SSH:    ssh -6 root@nova.hetzner.cboxlab.com"
echo "Logs:   podman logs -f nginx-proxy"
echo ""
