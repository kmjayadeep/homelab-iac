# Archive

Decommissioned stacks kept for reference. Nothing here is applied or
tracked by Renovate.

- `hetzner/`: the `nova` Hetzner VM (psuite Syncthing, SilverBullet wiki,
  Fava behind nginx). Destroyed on 2026-10-31 via `terraform destroy`;
  the committed state is empty. psuite data lives on the local workstation.
- `pluto/`: the old `titania` k3s master VM (VMID 101) on the pluto node,
  managed with the Telmate provider. The VM was deleted by hand on
  2026-11-14; the state still lists it and must not be applied. Pluto's
  ACME resources stay in `cosmos/proxmox/node-pluto.tf`.
