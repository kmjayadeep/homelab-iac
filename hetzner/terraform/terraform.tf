terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5.0"
    }
  }

  required_version = ">= 1.5"
}

provider "hcloud" {
}

provider "cloudflare" {
  # API token will be provided via CLOUDFLARE_API_TOKEN environment variable
}
