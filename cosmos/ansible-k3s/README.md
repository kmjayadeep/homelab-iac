# K3s Master Node Ansible Setup

This Ansible project automates the deployment and management of a K3s master node with support for future worker nodes.

## Features

- **Native K3s installation** with embedded etcd for HA
- **Systemd service** for automatic startup and management
- **Automated installation** of all prerequisites and dependencies
- **Firewall configuration** using UFW
- **Easy cluster management** with dedicated playbooks for start/stop/restart/update
- **Customizable configuration** through group variables
- **IPv4 and IPv6 dual-stack networking**
- **Support for external CNI** (Flannel disabled, ready for Cilium/Calico)
- **iSCSI and NFS support** for persistent storage (Longhorn ready)
- **Tailscale integration** for secure networking

## Prerequisites

- Ansible 2.9 or higher installed on your local machine
- SSH access to the target server (titania.cosmos.cboxlab.com)
- SSH key configured for the `ansible` user
- Target server running Debian/Ubuntu
- At least 2GB RAM and 20GB disk space

## Installation

### 1. Install Ansible Collections

First, install the required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure Variables

Edit `inventory/group_vars/k3s.yml` to customize your K3s settings:

```yaml
k3s_version: "v1.33.0+k3s1"
k3s_node_ip_v4: "192.168.1.66"
k3s_node_ip_v6: "fe80::be24:11ff:fe0f:5e1d"
k3s_tls_san: "titania.cosmos.cboxlab.com"
```

### 3. Verify Connectivity

Test your SSH connection and Ansible setup:

```bash
ansible all -m ping
```

## Usage

### Initial Setup

Deploy the K3s master node for the first time:

```bash
ansible-playbook playbooks/setup.yml
```

This will:
- Install system packages (curl, git, vim, open-iscsi, nfs-common)
- Load kernel modules (br_netfilter, overlay, IPv6 tables)
- Configure sysctl parameters for K3s
- Install and configure Tailscale
- Download and install K3s binary
- Configure K3s with all specified flags
- Create and enable the K3s systemd service
- Configure the firewall
- Set up kubeconfig for the cosmos user

### Cluster Management

**Start the cluster:**
```bash
ansible-playbook playbooks/start.yml
```

**Stop the cluster:**
```bash
ansible-playbook playbooks/stop.yml
```

**Restart the cluster:**
```bash
ansible-playbook playbooks/restart.yml
```

**Update K3s version:**
```bash
# Edit k3s_version in group_vars/k3s.yml first
ansible-playbook playbooks/update.yml
```

### Access the Cluster

After installation, the kubeconfig is available at `/home/cosmos/.kube/config` on the master node.

To use kubectl from the master node:

```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo su - cosmos
kubectl get nodes
```

To copy kubeconfig to your local machine:

```bash
scp ansible@titania.cosmos.cboxlab.com:/home/cosmos/.kube/config ~/.kube/k3s-config
export KUBECONFIG=~/.kube/k3s-config
kubectl get nodes
```

### View Cluster Logs

To check the K3s service logs:

```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo journalctl -u k3s -f
```

Or view recent logs:
```bash
sudo journalctl -u k3s -n 100
```

## Configuration

### K3s Configuration

The cluster is configured with the following settings:

| Setting | Value | Description |
|---------|-------|-------------|
| `k3s_version` | v1.33.0+k3s1 | K3s version to install |
| `cluster-init` | true | Enable embedded etcd for HA |
| `cluster-cidr` | 10.42.0.0/16, 2001:cafe:42::/96 | Pod network CIDRs (IPv4/IPv6) |
| `service-cidr` | 10.43.0.0/16, 2001:cafe:43::/112 | Service network CIDRs (IPv4/IPv6) |
| `node-ip` | 192.168.1.66, fe80::be24:11ff:fe0f:5e1d | Node IPs (IPv4/IPv6) |
| `flannel-backend` | none | External CNI (Flannel disabled) |
| `kube-proxy-arg` | proxy-mode=ipvs | Use IPVS for kube-proxy |

### Disabled Components

The following components are disabled to allow for custom implementations:

- traefik (use your own ingress controller)
- servicelb (use MetalLB or other load balancer)
- metrics-server (install separately if needed)
- local-storage (use Longhorn or other CSI driver)
- helm-controller (manage Helm releases externally)

### Network Ports

The firewall is configured to allow the following ports:

- **6443/tcp** - Kubernetes API server
- **10250/tcp** - Kubelet metrics
- **2379-2380/tcp** - etcd (for HA clusters)
- **8472/udp** - Flannel VXLAN (if needed later)
- **30000-32767/tcp** - NodePort service range
- **22/tcp** - SSH

## Adding Worker Nodes

To add worker nodes to the cluster:

1. Retrieve the node token from the master:
```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo cat /var/lib/rancher/k3s/server/node-token
```

2. Install K3s on the worker node:
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://titania.cosmos.cboxlab.com:6443 \
  K3S_TOKEN=<node-token> sh -
```

## Storage Configuration

### iSCSI (Longhorn)

The cluster is configured with open-iscsi support for Longhorn distributed storage:

- iSCSI initiator is configured with hostname-based naming
- iscsid service is enabled and running

To install Longhorn:
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```

### NFS

NFS client support is installed and rpcbind is configured for NFS-based persistent volumes.

## Troubleshooting

### Cluster not starting

Check service status and logs:
```bash
sudo systemctl status k3s
sudo journalctl -u k3s -n 100
```

### Can't access API server

1. Verify the service is running: `sudo systemctl status k3s`
2. Check firewall rules: `sudo ufw status`
3. Verify port is listening: `sudo ss -tlnp | grep 6443`

### Update K3s

To update to a new version:
1. Edit `k3s_version` in `inventory/group_vars/k3s.yml`
2. Run: `ansible-playbook playbooks/update.yml`

### Reset K3s

To completely reset K3s:
```bash
ssh ansible@titania.cosmos.cboxlab.com
sudo /usr/local/bin/k3s-killall.sh
sudo rm -rf /var/lib/rancher/k3s
sudo systemctl restart k3s
```

## Advanced Configuration

### Installing a CNI

Since Flannel is disabled, you can install your preferred CNI:

**Cilium:**
```bash
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/master/install/kubernetes/quick-install.yaml
```

**Calico:**
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### System Configuration

The following system parameters are configured:

- `fs.inotify.max_user_instances=1024` - Increased inotify watches
- `vm.dirty_ratio=10`, `vm.dirty_background_ratio=5` - VM performance tuning
- `net.ipv4.ip_forward=1`, `net.ipv6.conf.all.forwarding=1` - IP forwarding enabled

### Tailscale

Tailscale is installed and configured with `--accept-dns=false` to prevent DNS conflicts with K3s.

## Maintenance

### Regular Tasks

1. **Monitor cluster health** with `kubectl get nodes` and `kubectl get pods -A`
2. **Check logs** for any errors: `sudo journalctl -u k3s -f`
3. **Update K3s** periodically with `ansible-playbook playbooks/update.yml`
4. **Backup etcd** data from `/var/lib/rancher/k3s/server/db/`

### Manual Commands

```bash
# Check cluster status
ansible k3s_masters -m command -a "systemctl status k3s" -b

# Check disk usage
ansible k3s_masters -m command -a "df -h /var/lib/rancher" -b

# View running pods
ansible k3s_masters -m command -a "sudo -u cosmos kubectl get pods -A" -b
```

## Security Notes

- Keep the SSH key secure
- Regularly update K3s with `ansible-playbook playbooks/update.yml`
- Protect the node token at `/var/lib/rancher/k3s/server/node-token`
- Monitor cluster logs for suspicious activity
- Keep kubeconfig files secure (they have cluster admin access)
- Consider implementing RBAC policies for production use

## License

MIT

## Credits

- K3s: [Rancher/SUSE](https://k3s.io/)
- Ansible: [Red Hat](https://www.ansible.com/)
