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

echo "Installing collections..."
ansible-galaxy collection install -r requirements.yml

echo "Deploying to nova..."

# Check for required environment variable
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Error: CLOUDFLARE_API_TOKEN environment variable is required"
    echo "Export it first: export CLOUDFLARE_API_TOKEN=your-token"
    exit 1
fi

ansible-playbook playbooks/setup.yml

echo ""
echo "✅ Done!"
echo ""
echo "Access: https://psuite.hetzner.cboxlab.com"
echo "SSH:    ssh -6 root@psuite.hetzner.cboxlab.com"
echo "Logs:   podman logs -f nginx-app"
echo ""
