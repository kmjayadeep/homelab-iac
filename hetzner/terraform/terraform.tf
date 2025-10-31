terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54.0"
    }
  }
  
  required_version = ">= 1.5"
}

provider "hcloud" {
}
