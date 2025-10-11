#!/usr/bin/env bash
# Valheim Server Deployment Script

set -e

echo "==========================================="
echo "Valheim Server Ansible Deployment"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed.${NC}"
    echo "Please install Ansible first:"
    echo "  pip install ansible"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing required Ansible collections...${NC}"
ansible-galaxy collection install -r requirements.yml

echo ""
echo -e "${YELLOW}Step 2: Testing connectivity to server...${NC}"
if ansible all -m ping; then
    echo -e "${GREEN}✓ Connection successful!${NC}"
else
    echo -e "${RED}✗ Connection failed. Please check your SSH configuration.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Deploying Valheim server...${NC}"
echo "This may take several minutes..."
ansible-playbook playbooks/setup.yml

echo ""
echo -e "${GREEN}==========================================="
echo "Deployment Complete!"
echo "===========================================${NC}"
echo ""
echo "Your Valheim server should now be running!"
echo ""
echo "Connection details:"
echo "  Address: valheim-rivers.cosmos.cboxlab.com:2456"
echo ""
echo "Useful commands:"
echo "  View logs:     ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo journalctl -u valheim -f'"
echo "  Stop server:   ansible-playbook playbooks/stop.yml"
echo "  Start server:  ansible-playbook playbooks/start.yml"
echo "  Restart:       ansible-playbook playbooks/restart.yml"
echo "  Update:        ansible-playbook playbooks/update.yml"
echo ""
echo -e "${YELLOW}IMPORTANT: Change the server password in group_vars/valheim_servers.yml!${NC}"
echo ""

