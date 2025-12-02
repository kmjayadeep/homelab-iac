terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
  required_version = "> 1.9.8"
}

