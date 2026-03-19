# Scripts

Utility scripts for host-level operational fixes that do not cleanly fit into the Terraform, Ansible, or NixOS parts of this repo.

## `disable_offloads.sh`

Disables a set of NIC offload features at runtime and installs a systemd oneshot unit to re-apply the settings on boot.

This was added for Proxmox hosts that show Intel `e1000e` transmit-ring hangs such as:

```text
e1000e ... Detected Hardware Unit Hang
```

On affected Intel I21x adapters, disabling offloads can stop the host from dropping off the network long enough to lose NFS storage, Tailscale connectivity, and Proxmox management access.

### Usage

Run the script as root and pass the physical interface name:

```bash
sudo ./scripts/disable_offloads.sh eno1
```

If you are not sure which interface backs the Proxmox bridge:

```bash
ip -br link
bridge link
```

### What it changes

- Applies `ethtool -K <iface> ... off` immediately.
- Creates `/etc/systemd/system/disable-offload-<iface>.service`.
- Enables and starts that unit so the settings persist across reboots.

### Notes

- Start with the actual physical NIC, not `vmbr0`.
- The script is intended as a mitigation, not a hardware fix. If hangs continue, also check cable, switch port, BIOS/firmware, kernel version, and consider moving management traffic to a different NIC.
- To remove the persistent change:

```bash
sudo systemctl disable --now disable-offload-<iface>.service
sudo rm /etc/systemd/system/disable-offload-<iface>.service
sudo systemctl daemon-reload
```
