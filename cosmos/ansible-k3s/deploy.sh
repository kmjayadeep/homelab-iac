#!/usr/bin/env bash
# K3s Master Node Deployment Script

set -e

echo "==========================================="
echo "K3s Master Node Ansible Deployment"
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
echo -e "${YELLOW}Step 3: Deploying K3s master node...${NC}"
echo "This may take several minutes..."
ansible-playbook playbooks/setup.yml

echo ""
echo -e "${GREEN}==========================================="
echo "Deployment Complete!"
echo "===========================================${NC}"
echo ""
echo "Your K3s master node should now be running!"
echo ""
echo "Cluster details:"
echo "  API Server: https://titania.cosmos.cboxlab.com:6443"
echo "  Kubeconfig: /home/cosmos/.kube/config"
echo ""
echo "Access the cluster:"
echo "  From master: ssh ansible@titania.cosmos.cboxlab.com -t 'sudo su - cosmos'"
echo "  Then run:    kubectl get nodes"
echo ""
echo "Worker node token location:"
echo "  /var/lib/rancher/k3s/server/node-token"
echo ""
echo "Useful commands:"
echo "  View logs:     ssh ansible@titania.cosmos.cboxlab.com 'sudo journalctl -u k3s -f'"
echo "  Stop cluster:  ansible-playbook playbooks/stop.yml"
echo "  Start cluster: ansible-playbook playbooks/start.yml"
echo "  Restart:       ansible-playbook playbooks/restart.yml"
echo "  Update:        ansible-playbook playbooks/update.yml"
echo ""
