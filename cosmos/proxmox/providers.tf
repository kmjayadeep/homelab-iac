terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
    minio = {
      source  = "aminueza/minio"
      version = "2.5.1"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://jupiter.cosmos.cboxlab.com:8006/api2/json"
}

provider "proxmox" {
  alias = "mars"
  pm_api_url = "https://mars.cosmos.cboxlab.com:8006/api2/json"
}

provider "minio" {
  minio_server = "minio.cosmos.cboxlab.com"
  minio_ssl    = true
}
