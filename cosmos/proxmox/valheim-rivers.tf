resource "proxmox_virtual_environment_vm" "valheim_rivers" {
  provider  = proxmox-bpg.mars-bpg
  name      = "valheim-rivers"
  node_name = "mars"

  machine     = "q35"
  bios        = "ovmf"
  description = "Valheim server with the seed IEatPizzaP"
  tags        = ["game", "valheim"]

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
    import_from  = proxmox_virtual_environment_download_file.latest_debian_13_qcow2_img.id
    interface    = "virtio0"
    size         = 100
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.valheim_server_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_file" "valheim_server_user_data" {
  provider     = proxmox-bpg.mars-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "mars"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: valheim-rivers
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
      - name: valheim
        groups:
          - games
        shell: /bin/bash
        create_home: true
        home: /home/valheim
        system: false
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
      # Enable and start qemu-guest-agent
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      
      
      # Final setup indicator
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "valheim_rivers_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "valheim_rivers" {
  zone_id = var.cloudflare_zone_id
  name    = "valheim-rivers.cosmos.cboxlab.com"
  type    = "A"
  comment = "Valheim Rivers server (IEatPizzaP seed)"
  content = proxmox_virtual_environment_vm.valheim_rivers.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}

module "valheim_rivers_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valheim-rivers-backup"
  create_user = true
}