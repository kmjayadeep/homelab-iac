#!/usr/bin/env bash
# Windrose Server Deployment Script

set -e

echo "==========================================="
echo "Windrose Server Ansible Deployment"
echo "==========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
    echo -e "${GREEN}Connection successful!${NC}"
else
    echo -e "${RED}Connection failed. Please check your SSH configuration.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Deploying Windrose server...${NC}"
echo "This may take several minutes..."
ansible-playbook playbooks/setup.yml

echo ""
echo -e "${GREEN}==========================================="
echo "Deployment Complete!"
echo "===========================================${NC}"
echo ""
echo "Your Windrose server should now be running!"
echo ""
echo "Useful commands:"
echo "  View logs:     ssh ansible@windrose.cosmos.cboxlab.com 'sudo docker compose --project-directory /home/windrose/windrose-server logs -f windrose'"
echo "  Stop server:   ansible-playbook playbooks/stop.yml"
echo "  Start server:  ansible-playbook playbooks/start.yml"
echo "  Restart:       ansible-playbook playbooks/restart.yml"
echo "  Update:        ansible-playbook playbooks/update.yml"
echo ""
echo "Invite code:"
echo "  ssh ansible@windrose.cosmos.cboxlab.com 'sudo cat /home/windrose/windrose-server/data/R5/ServerDescription.json'"
echo ""
