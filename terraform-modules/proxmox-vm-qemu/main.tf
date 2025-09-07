resource "proxmox_vm_qemu" "this" {
  vmid                   = var.vmid
  target_node            = var.target_node
  agent                  = 1
  bios                   = "seabios"
  clone                  = var.clone
  ciupgrade              = false
  define_connection_info = false
  description            = var.desc
  force_create           = false
  full_clone             = var.clone != "" ? true : false
  hotplug                = "network,disk,usb"
  ipconfig0              = "ip=${var.ipv4_addr},gw=${var.ipv4_gw},ip6=dhcp"
  kvm                    = true
  memory                 = var.memory
  balloon                = var.balloon != null ? var.balloon : var.memory / 2
  name                   = var.name
  onboot                 = var.onboot
  protection             = false
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  sshkeys                = var.sshkeys
  tablet                 = true
  vm_state               = var.vm_state
  tags                   = var.tags
  cpu {
    cores                  = var.cores
    sockets = 1
  }
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.storage
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          format  = "raw"
          size    = var.disk_size
          storage = var.storage
        }
      }
    }
  }
  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}
