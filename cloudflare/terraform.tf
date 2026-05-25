terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.19.1"
    }
  }
}

provider "cloudflare" {
  # Uses CLOUDFLARE_API_TOKEN for R2 resources.
}

provider "cloudflare" {
  alias     = "dns"
  api_token = var.cloudflare_dns_api_token
}
