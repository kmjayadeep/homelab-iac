resource "cloudflare_r2_bucket" "postgres-cosmos-backup" {
  account_id    = "de346322c951eb2e500a79df4f02317f"
  name          = "postgres-cosmos-backup"
  storage_class = "Standard"
  jurisdiction  = "eu"
}

resource "cloudflare_dns_record" "baskit" {
  provider = cloudflare.dns

  zone_id = "efad963cb5839dca8c2674cccf34e37d"
  name    = "baskit.cboxlab.com"
  content = "baskit-b54b5.web.app"
  type    = "CNAME"
  ttl     = 300
  proxied = false

  comment = "Baskit Firebase hosting - managed by Terraform"
}

resource "cloudflare_dns_record" "baskit_verification" {
  provider = cloudflare.dns

  zone_id = "efad963cb5839dca8c2674cccf34e37d"
  name    = "baskit.cboxlab.com"
  content = "hosting-site=baskit-b54b5"
  type    = "TXT"
  ttl     = 300

  comment = "Baskit Firebase hosting verification - managed by Terraform"
}
