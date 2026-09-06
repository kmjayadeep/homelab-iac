resource "proxmox_virtual_environment_vm" "valheim_skadi" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "valheim-skadi"
  node_name = "jupiter"
  started   = true

  machine     = "q35"
  bios        = "ovmf"
  description = "Vanilla Valheim 1.0 dedicated server"
  tags        = ["game", "valheim"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
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
    user_data_file_id = proxmox_virtual_environment_file.valheim_skadi_user_data.id
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

resource "proxmox_virtual_environment_file" "valheim_skadi_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: valheim-skadi
    timezone: Europe/Berlin
    users:
      - name: valheim
        groups:
          - games
        shell: /bin/bash
        create_home: true
        home: /home/valheim
        system: false
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

    file_name = "valheim_skadi_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "valheim_skadi" {
  zone_id = var.cloudflare_zone_id
  name    = "valheim-skadi.cosmos.cboxlab.com"
  type    = "A"
  comment = "Vanilla Valheim 1.0 server"
  content = proxmox_virtual_environment_vm.valheim_skadi.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}

module "valheim_skadi_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valheim-skadi-backup"
  create_user = true
}
