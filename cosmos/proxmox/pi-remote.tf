resource "proxmox_virtual_environment_vm" "pi_remote" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "pi-remote"
  node_name = "jupiter"
  started   = true
  on_boot   = true

  machine     = "q35"
  bios        = "ovmf"
  description = "Pi Remote VM"
  tags        = ["development", "pi-remote"]

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
    import_from  = proxmox_download_file.latest_debian_13_qcow2_img.id
    interface    = "virtio0"
    size         = 100
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.pi_remote_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_file" "pi_remote_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: pi-remote
    timezone: Europe/Berlin
    users:
      - name: "${var.cloudinit_username}"
        groups: [sudo]
        shell: /bin/bash
        ssh_authorized_keys:
          - "${var.cloudinit_ssh_public_key}"
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: true
      - name: ansible
        gecos: Ansible User
        groups: [sudo]
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
          - "${var.cloudinit_ssh_public_key}"
    package_update: true
    packages:
      - qemu-guest-agent
      - curl
    runcmd:
      - systemctl enable --now qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "pi-remote_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "pi_remote" {
  zone_id = var.cloudflare_zone_id
  name    = "pi-remote.cosmos.cboxlab.com"
  type    = "A"
  comment = "Pi Remote VM"
  content = proxmox_virtual_environment_vm.pi_remote.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}
