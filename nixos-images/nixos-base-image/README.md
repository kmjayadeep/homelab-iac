# Nixs base image for promxox
This is the iac for nixos base image to be used as a template in proxmox

## Using this base image

Build the image

```sh
nix build .#proxmox
```

Copy to target proxmox storage

```
scp ./result/vzdump-qemu-nixos-*.vma.zst jupiter:/mnt/pve/templates-nfs/dump/
```

In proxmox UI

* Go to datacenter->[node]->[storage]->backups
* Restore the image which was uploaded now
* Provide name, cpu, memory etc. Don't auto-start
* Open the new VM -> click on `more` -> convert to template

## Testing the template manually

* click on base image -> more -> clone
* Once cloned, provide cloud-init parameters as needed
* Adjust hard-disk size as needed.
* start and test
