terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
    minio = {
      source  = "aminueza/minio"
      version = "2.5.1"
    }
    proxmox-bpg = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://mars.cosmos.cboxlab.com:8006/api2/json"
  pm_tls_insecure = true
}

provider "proxmox" {
  alias           = "mars"
  pm_api_url      = "https://mars.cosmos.cboxlab.com:8006/api2/json"
  pm_tls_insecure = true
}

provider "proxmox-bpg" {
  alias           = "mars-bpg"
  endpoint      = "https://mars.cosmos.cboxlab.com:8006/"
  insecure = true
  ssh {
    agent = true
    username = "root"
  }
}

provider "minio" {
  minio_server = "minio.cosmos.cboxlab.com"
  minio_ssl    = true
}
