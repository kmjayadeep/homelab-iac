resource "proxmox_vm_qemu" "darkland" {
  target_node            = "jupiter"
  vmid                   = 200
  balloon                = 0
  bios                   = "seabios"
  boot                   = "order=scsi0;ide2;net0"
  cores                  = 4
  cpu                    = "x86-64-v2-AES"
  define_connection_info = false
  force_create           = false
  full_clone             = false
  hotplug                = "network,disk,usb"
  kvm                    = true
  memory                 = 4096
  name                   = "darkland"
  numa                   = false
  onboot                 = true
  protection             = false
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  sockets                = 1
  tablet                 = true
  vm_state               = "running"
  tags                   = "game,valheim"
  disks {
    ide {
      ide2 {
        cdrom {
          iso = "templates-nfs:iso/latest-nixos-minimal-x86_64-linux.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = "100G"
          storage = "local-lvm"
        }
      }
    }
  }
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }
}
