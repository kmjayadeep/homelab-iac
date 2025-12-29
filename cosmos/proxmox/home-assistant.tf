data "proxmox_virtual_environment_file" "haos_img" {
  provider = proxmox-bpg.jupiter-bpg

  node_name    = "jupiter"
  datastore_id = "nfs-templates"
  content_type = "import"
  file_name    = "haos_ova-16.3.qcow2"
}

resource "proxmox_virtual_environment_file" "home_assistant_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: home-assistant
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
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      # Enable and start qemu-guest-agent
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      
      
      # Final setup indicator
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "home_assistant_cloudinit.yaml"
  }
}


resource "proxmox_virtual_environment_vm" "home-assistant" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "home-assistant"
  node_name = "jupiter"

  machine     = "q35"
  bios        = "ovmf"
  description = "Home Assistant VM"
  tags        = ["automation"]

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
    import_from  = data.proxmox_virtual_environment_file.haos_img.id
    interface    = "virtio0"
    size         = 100
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.home_assistant_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "cloudflare_dns_record" "home-assistant" {
  zone_id = var.cloudflare_zone_id
  name    = "home-assistant.cosmos.cboxlab.com"
  type    = "A"
  comment = "Home Assistant VM"
  content = proxmox_virtual_environment_vm.home-assistant.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}
