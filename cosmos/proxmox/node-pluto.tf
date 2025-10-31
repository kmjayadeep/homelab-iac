resource "proxmox_virtual_environment_acme_account" "jd-pluto" {
  provider  = proxmox-bpg.pluto-bpg
  name      = "jd-pluto"
  contact   = var.acme_email
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf"
}

resource "proxmox_virtual_environment_acme_dns_plugin" "jd-cloudflare-pluto" {
  provider = proxmox-bpg.pluto-bpg
  plugin   = "cloudflare"
  api      = "cf"
  data = {
    CF_Token = var.cloudflare_api_token
  }
}
