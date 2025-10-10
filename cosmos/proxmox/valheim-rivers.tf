resource "proxmox_virtual_environment_vm" "valheim-rivers" {
  provider = proxmox-bpg.mars-bpg
  name      = "valheim-rivers"
  node_name = "mars"
  bios        = "ovmf"

  clone {
    vm_id = proxmox_virtual_environment_vm.debian_13_template.id
  }

  agent {
    # NOTE: The agent is installed and enabled as part of the cloud-init configuration in the template VM, see cloud-config.tf
    # The working agent is *required* to retrieve the VM IP addresses.
    # If you are using a different cloud-init configuration, or a different clone source
    # that does not have the qemu-guest-agent installed, you may need to disable the `agent` below and remove the `vm_ipv4_address` output.
    # See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#qemu-guest-agent for more details.
    enabled = false
  }

  memory {
    dedicated = 2048
  }

  initialization {
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.121/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      username = var.cloudinit_username
      keys     = [var.cloudinit_ssh_public_key]
      password = var.cloudinit_password
    }
  }
}
