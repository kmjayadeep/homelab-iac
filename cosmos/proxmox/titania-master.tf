resource "proxmox_virtual_environment_vm" "titania-master" {
  provider  = proxmox-bpg.jupiter-bpg
  name      = "titania-master"
  node_name = "jupiter"

  machine     = "q35"
  bios        = "ovmf"
  description = "Titania master node"
  tags        = ["k8s"]

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 16384
  }

  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
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
    user_data_file_id = proxmox_virtual_environment_file.titania_master_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }
}

resource "proxmox_virtual_environment_file" "titania_master_user_data" {
  provider     = proxmox-bpg.jupiter-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "jupiter"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: titania-master
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

    file_name = "titania_master_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "titania_master" {
  zone_id = var.cloudflare_zone_id
  name    = "titania.cosmos.cboxlab.com"
  type    = "A"
  comment = "titania master node"
  content = proxmox_virtual_environment_vm.titania-master.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}
