resource "proxmox_virtual_environment_download_file" "latest_debian_13_qcow2_img" {
  provider = proxmox-bpg.mars-bpg

  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"

  content_type = "import"
  datastore_id = "nfs-templates"
  node_name    = "mars"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "debian-13-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_file" "debian_13_user_data" {
  provider     = proxmox-bpg.mars-bpg
  content_type = "snippets"
  datastore_id = "nfs-templates"
  node_name    = "mars"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: debian-13
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
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "debian_13_cloudinit.yaml"
  }
}
