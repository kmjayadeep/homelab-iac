resource "proxmox_acme_account" "jd-orion" {
  provider  = proxmox-bpg.orion-bpg
  name      = "jd-orion"
  contact   = var.acme_email
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf"
}

resource "proxmox_acme_dns_plugin" "jd-cloudflare-orion" {
  provider = proxmox-bpg.orion-bpg
  plugin   = "cloudflare"
  api      = "cf"
  data = {
    CF_Token = var.cloudflare_api_token
  }
}

resource "cloudflare_dns_record" "orion" {
  zone_id = var.cloudflare_zone_id
  name    = "orion.cosmos.cboxlab.com"
  type    = "A"
  comment = "Orion Proxmox node"
  content = "192.168.1.18"
  proxied = false
  ttl     = 300
}
