#!/usr/bin/env bash
# K3s Worker Node Deployment Script

set -e

echo "==========================================="
echo "K3s Worker Node Ansible Deployment"
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
echo -e "${YELLOW}Step 2: Testing connectivity to worker nodes...${NC}"
if ansible k3s_workers -m ping; then
    echo -e "${GREEN}✓ Connection successful!${NC}"
else
    echo -e "${RED}✗ Connection failed. Please check your SSH configuration.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Verifying master node is accessible...${NC}"
if ansible k3s_masters -m ping; then
    echo -e "${GREEN}✓ Master node accessible!${NC}"
else
    echo -e "${RED}✗ Cannot reach master node. Worker deployment requires master access to fetch node token.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 4: Deploying K3s worker nodes...${NC}"
echo "This may take several minutes..."
ansible-playbook playbooks/setup-workers.yml

echo ""
echo -e "${GREEN}==========================================="
echo "Worker Deployment Complete!"
echo "===========================================${NC}"
echo ""
echo "Your K3s worker nodes should now be running!"
echo ""
echo "Verify nodes joined the cluster:"
echo "  From master: ssh ansible@titania.cosmos.cboxlab.com -t 'sudo -u cosmos kubectl get nodes'"
echo "  From local:  kubectl get nodes"
echo ""
echo "Useful commands:"
echo "  View logs:      ssh ansible@192.168.1.79 'sudo journalctl -u k3s-agent -f'"
echo "  Stop workers:   ansible-playbook playbooks/stop-workers.yml"
echo "  Start workers:  ansible-playbook playbooks/start-workers.yml"
echo "  Restart:        ansible-playbook playbooks/restart-workers.yml"
echo ""

