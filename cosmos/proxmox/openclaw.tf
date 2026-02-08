resource "proxmox_virtual_environment_vm" "openclaw" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "openclaw"
  node_name = "jupiter"

  machine     = "q35"
  bios        = "ovmf"
  description = "OpenClaw - personal AI assistant that actually does things"
  tags        = ["openclaw"]

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.latest_debian_13_qcow2_img.id
    interface    = "virtio0"
    size         = 200
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.openclaw_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

}

resource "proxmox_virtual_environment_file" "openclaw_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: openclaw
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

    file_name = "openclaw_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "openclaw" {
  zone_id = var.cloudflare_zone_id
  name    = "openclaw.cosmos.cboxlab.com"
  type    = "A"
  comment = "Openclaw VM"
  content = proxmox_virtual_environment_vm.openclaw.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}
