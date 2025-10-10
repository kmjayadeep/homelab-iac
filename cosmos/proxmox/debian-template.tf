resource "proxmox_virtual_environment_vm" "debian_13_template" {
  provider = proxmox-bpg.mars-bpg
  name      = "debian-13-base"
  node_name = "mars"

  template = true
  started  = false

  machine     = "q35"
  bios        = "ovmf"
  description = "Debian 13 cloud image base template"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id = "ssd-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "ssd-lvm"
    import_from  = proxmox_virtual_environment_download_file.latest_debian_13_qcow2_img.id
    interface    = "virtio0"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "debian"
      password = "debian"
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = true
  }
}

resource "proxmox_virtual_environment_download_file" "latest_debian_13_qcow2_img" {
  provider = proxmox-bpg.mars-bpg

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"

  content_type = "import"
  datastore_id = "nfs-templates"
  node_name    = "mars"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "debian-13-genericcloud-amd64.qcow2"
}
