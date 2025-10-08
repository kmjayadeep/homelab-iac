resource "proxmox_virtual_environment_vm" "debian_13_template" {
  provider = proxmox-bpg.mars-bpg
  name      = "debian-13-base"
  node_name = "mars"

  template = true
  started  = false

  machine     = "q35"
  bios        = "ovmf"
  description = "Managed by Terraform"

  cpu {
    cores = 2
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

    #user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }

  network_device {
    bridge = "vmbr0"
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
