resource "proxmox_vm_qemu" "this" {
  vmid                   = var.vmid
  target_node            = var.target_node
  agent                  = 1
  bios                   = "seabios"
  clone                  = var.clone
  ciupgrade              = false
  cores                  = var.cores
  define_connection_info = false
  desc                   = var.desc
  force_create           = false
  full_clone             = true
  hotplug                = "network,disk,usb"
  ipconfig0              = "ip=${var.ipv4_addr},gw=${var.ipv4_gw},ip6=dhcp"
  kvm                    = true
  memory                 = var.memory
  name                   = var.name
  onboot                 = true
  protection             = false
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  sockets                = 1
  sshkeys                = var.sshkeys
  tablet                 = true
  vm_state               = var.vm_state
  tags                   = var.tags
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          format  = "raw"
          size    = var.disk_size
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
