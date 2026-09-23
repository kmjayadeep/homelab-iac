resource "proxmox_download_file" "ubuntu_26_04_orion_cloudimg" {
  provider = proxmox-bpg.orion-bpg

  url = "https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img"

  content_type = "import"
  datastore_id = "local"
  node_name    = "orion"
  file_name    = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "titania_gpu" {
  provider  = proxmox-bpg.orion-bpg
  name      = "titania-gpu"
  node_name = "orion"
  started   = true
  on_boot   = true

  machine     = "q35"
  bios        = "ovmf"
  description = "Titania GPU K3s worker"
  tags        = ["kubernetes", "gpu", "ai"]

  cpu {
    cores = 8
    type  = "host"
  }

  memory {
    dedicated = 24576
  }

  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.ubuntu_26_04_orion_cloudimg.id
    interface    = "virtio0"
    size         = 512
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.titania_gpu_user_data.id
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  hostpci {
    device = "hostpci0"
    id     = "0000:03:00.0"
    pcie   = true
  }
}

resource "proxmox_virtual_environment_file" "titania_gpu_user_data" {
  provider     = proxmox-bpg.orion-bpg
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "orion"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: titania-gpu
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
      - linux-firmware
      - mesa-utils
      - intel-media-va-driver
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "titania_gpu_cloudinit.yaml"
  }
}

resource "cloudflare_dns_record" "titania_gpu" {
  zone_id = var.cloudflare_zone_id
  name    = "titania-gpu.cosmos.cboxlab.com"
  type    = "A"
  comment = "Titania GPU K3s worker"
  content = proxmox_virtual_environment_vm.titania_gpu.ipv4_addresses[1][0]
  proxied = false
  ttl     = 300
}
