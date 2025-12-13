resource "proxmox_virtual_environment_vm" "titania-worker1" {
  provider  = proxmox-bpg.mars-bpg
  name      = "titania-worker1"
  node_name = "mars"

  machine     = "q35"
  bios        = "ovmf"
  description = "Titania worker1 node"
  tags        = ["k8s"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  efi_disk {
    datastore_id = "ssd-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "ssd-lvm"
    import_from  = proxmox_virtual_environment_download_file.latest_debian_13_qcow2_img.id
    interface    = "virtio0"
    size         = 300
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.titania_worker1_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_file" "titania_worker1_user_data" {
  provider     = proxmox-bpg.mars-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "mars"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: titania-worker1
    timezone: Europe/Berlin
    users:
      - name: "${var.cloudinit_username}"
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - "${var.cloudinit_ssh_public_key}"
        sudo: ALL=(ALL) NOPASSWD:ALL
        plain_text_passwd: "${var.cloudinit_password}"
        lock_passwd: false
      - name: ansible
        gecos: Ansible User
        groups: users,admin,wheel
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
          - "${var.cloudinit_ssh_public_key}"
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      
      
      # Final setup indicator
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "titania_worker1_cloudinit.yaml"
  }
}
