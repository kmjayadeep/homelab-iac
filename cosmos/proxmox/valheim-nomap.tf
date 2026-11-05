resource "proxmox_virtual_environment_vm" "valheim_nomap" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "valheim-nomap"
  node_name = "jupiter"
  started   = true

  machine     = "q35"
  bios        = "ovmf"
  description = "Valheim 1.0 no-map dedicated server"
  tags        = ["game", "valheim"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 6144
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
    user_data_file_id = proxmox_virtual_environment_file.valheim_nomap_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_file" "valheim_nomap_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: valheim-nomap
    timezone: Europe/Berlin
    users:
      - name: valheim
        groups:
          - games
        shell: /bin/bash
        homedir: /home/valheim
        ssh_authorized_keys:
          - "${var.cloudinit_ssh_public_key}"
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
      - systemctl enable --now qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "valheim_nomap_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "valheim_nomap" {
  zone_id = var.cloudflare_zone_id
  name    = "valheim-nomap.cosmos.cboxlab.com"
  type    = "A"
  comment = "Valheim nomap LAN address"
  content = proxmox_virtual_environment_vm.valheim_nomap.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "valheim_nomap_tailscale" {
  zone_id = var.cloudflare_zone_id
  name    = "valheim-nomap-tailscale.cosmos.cboxlab.com"
  type    = "A"
  comment = "Valheim nomap Tailscale address"
  content = "100.103.143.87"
  proxied = false
  ttl     = 300
}

module "valheim_nomap_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valheim-nomap-backup"
  create_user = true
}
