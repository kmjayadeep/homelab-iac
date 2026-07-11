resource "proxmox_virtual_environment_vm" "openclaw_chinnu" {
  provider  = proxmox-bpg.mars-bpg
  name      = "openclaw-chinnu"
  node_name = "mars"
  started   = true

  machine     = "q35"
  bios        = "ovmf"
  description = "OpenClaw Chinnu VM"
  tags        = ["openclaw", "chinnu"]

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  efi_disk {
    datastore_id = "ssd-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "ssd-lvm"
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
    user_data_file_id = proxmox_virtual_environment_file.openclaw_chinnu_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_file" "openclaw_chinnu_user_data" {
  provider     = proxmox-bpg.mars-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "mars"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: openclaw-chinnu
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

    file_name = "openclaw-chinnu_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "openclaw_chinnu" {
  zone_id = var.cloudflare_zone_id
  name    = "openclaw-chinnu.cosmos.cboxlab.com"
  type    = "A"
  comment = "OpenClaw Chinnu VM"
  content = proxmox_virtual_environment_vm.openclaw_chinnu.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}

module "openclaw_chinnu_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "openclaw-chinnu-backup"
  create_user = true
}
