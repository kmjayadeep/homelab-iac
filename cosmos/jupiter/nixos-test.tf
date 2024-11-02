resource "proxmox_vm_qemu" "nixos-test" {
  target_node            = "jupiter"
  agent                  = 1
  bios                   = "seabios"
  clone                  = "nixos-base"
  ciupgrade              = false
  cores                  = 2
  define_connection_info = false
  desc                   = "Test VM"
  force_create           = false
  full_clone             = true
  hotplug                = "network,disk,usb"
  ipconfig0              = "ip=192.168.1.64/24,gw=192.168.1.1,ip6=dhcp"
  kvm                    = true
  memory                 = 4098
  name                   = "nixos-test"
  onboot                 = true
  protection             = false
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  sockets                = 1
  sshkeys                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVFwMXBBljf+W5diHw9sz+A5AQhojFh8xXHCvznJkebVimhPU18dP7aL6K91tMdx+1rDbW3XyqWlAcuJY55j/G1JMyMGGTSCWkUlovZArqFAWxyadQ9s7Ev13bSF+h2qaL1x8tFAYK/L/LR4OOHSKXzqdeS2WeZgIFEuBW6HDnlGGV0aVVLo6f7wTIt4QK48IiUxKDo+giN5vmXtcBg0F88DhbDtLip3Yab6Sqm4v5PCIM4XiKkULqMLGqfQoUItFi0MGEq1P2qvQ/pVdHEjMoPjXfnwI0Jr4T6NN/QO8lsEfyYlI8qtZ2MvTYdqmOvrY37cYx2BJsIQvwC1wzERgqboEUk0qsRwNqIUcAbOaBIADDn11FUQyvYZ2S8QeIqiwkdyE+jJuPTTgzh5RtuFoqyKuIQohzPDIhAmr65xygcYUyM7vRji5F20dVxc92fNc7ec1FCsbPoSHdW41PkimO2+plyhMFkYrbRo2Hzi6pW+LkmPDbZTMWDo6RM07G+1DIGoDUmSxCQDgkoHHG+x6U0mKh2YSX9zwIxr/9h/dvEyWYCG09XNmxFlGHNNlb0Us52UJ4Ax53WnNoxECH0RDojRQkn3m3v0xxFU9C/RaER48N7ppEDjL9dtcM0lF714TbpBQYBM2oJYJIoCX0Cj/fyrSxofHTYARsnBzblDZA9Q== kmjayadeep@gmail.com"
  tablet                 = true
  vm_state               = "running"
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
          size    = "30G"
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
