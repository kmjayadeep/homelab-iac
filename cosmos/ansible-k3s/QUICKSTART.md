# K3s Master Node Quick Start Guide

## Initial Setup

1. **Install Ansible collections:**
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Configure your cluster settings:**
   Edit `inventory/group_vars/k3s.yml` and verify/change:
   - `k3s_version`: K3s version to install
   - `k3s_node_ip_v4`: Your node's IPv4 address
   - `k3s_node_ip_v6`: Your node's IPv6 address
   - `k3s_tls_san`: Your cluster's DNS name

3. **Test connectivity:**
   ```bash
   ansible all -m ping
   ```

4. **Deploy the K3s master:**
   ```bash
   ./deploy.sh
   ```
   
   Or manually:
   ```bash
   ansible-playbook playbooks/setup.yml
   ```

## Daily Operations

### Start/Stop/Restart

```bash
# Start
ansible-playbook playbooks/start.yml

# Stop
ansible-playbook playbooks/stop.yml

# Restart
ansible-playbook playbooks/restart.yml
```

### Update K3s

```bash
# Edit k3s_version in inventory/group_vars/k3s.yml first
ansible-playbook playbooks/update.yml
```

This will:
1. Stop K3s
2. Download and install the new K3s binary
3. Start K3s

### View Logs

```bash
# Live logs
ssh ansible@titania.cosmos.cboxlab.com 'sudo journalctl -u k3s -f'

# Recent logs
ssh ansible@titania.cosmos.cboxlab.com 'sudo journalctl -u k3s -n 100'
```

## Cluster Access

**From the master node:**
```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo su - cosmos
kubectl get nodes
kubectl get pods -A
```

**From your local machine:**
```bash
# Copy kubeconfig
scp ansible@titania.cosmos.cboxlab.com:/home/cosmos/.kube/config ~/.kube/k3s-config

# Use kubectl
export KUBECONFIG=~/.kube/k3s-config
kubectl get nodes
```

## File Locations

| Path | Description |
|------|-------------|
| `/usr/local/bin/k3s` | K3s binary |
| `/etc/rancher/k3s/` | K3s configuration directory |
| `/etc/rancher/k3s/config.yaml` | K3s configuration file |
| `/var/lib/rancher/k3s/` | K3s data directory |
| `/var/lib/rancher/k3s/server/node-token` | Token for adding worker nodes |
| `/home/cosmos/.kube/config` | User kubeconfig |
| `/etc/systemd/system/k3s.service` | Systemd service file |

## Systemd Commands

```bash
# Check status
sudo systemctl status k3s

# Start/Stop/Restart
sudo systemctl start k3s
sudo systemctl stop k3s
sudo systemctl restart k3s

# Enable/Disable auto-start
sudo systemctl enable k3s
sudo systemctl disable k3s
```

## Adding Worker Nodes

1. **Get the node token from the master:**
   ```bash
   ssh ansible@titania.cosmos.cboxlab.com
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

2. **Install K3s agent on worker:**
   ```bash
   curl -sfL https://get.k3s.io | K3S_URL=https://titania.cosmos.cboxlab.com:6443 \
     K3S_TOKEN=<node-token-from-step-1> sh -
   ```

3. **Verify node joined:**
   ```bash
   kubectl get nodes
   ```

## Configuration Changes

After modifying `inventory/group_vars/k3s.yml`:

```bash
# Re-run setup to apply changes
ansible-playbook playbooks/setup.yml
```

## Troubleshooting

### Cluster won't start
```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo systemctl status k3s
sudo journalctl -u k3s -n 100
```

### API server not accessible
```bash
# Check firewall
ssh ansible@titania.cosmos.cboxlab.com 'sudo ufw status'

# Verify server is listening
ssh ansible@titania.cosmos.cboxlab.com 'sudo ss -tlnp | grep 6443'
```

### Disk space issues
```bash
ansible k3s_masters -m command -a "df -h /var/lib/rancher" -b
```

### Reset cluster
```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo /usr/local/bin/k3s-killall.sh
sudo rm -rf /var/lib/rancher/k3s
sudo systemctl restart k3s
```

## Tips

- **Kubeconfig**: Accessible at `/home/cosmos/.kube/config` with DNS-based server URL
- **Node Token**: Found at `/var/lib/rancher/k3s/server/node-token` for adding workers
- **Network**: Dual-stack IPv4/IPv6 with external CNI (install Cilium/Calico as needed)
- **Storage**: iSCSI and NFS support included for Longhorn or NFS-based persistent volumes
- **Monitoring**: Install metrics-server separately if needed (`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`)
- **Backups**: etcd data is in `/var/lib/rancher/k3s/server/db/` - back this up regularly

## Common kubectl Commands

```bash
# Get all resources
kubectl get all -A

# Check node status
kubectl get nodes -o wide

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward
kubectl port-forward -n <namespace> <pod-name> 8080:80
```
