terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
  required_version = "> 1.9.8"
}

