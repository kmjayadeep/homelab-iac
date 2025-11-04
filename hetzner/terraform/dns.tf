# DNS Record for nova server IPv6
resource "cloudflare_dns_record" "nova_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = "nova.hetzner.${var.dns_domain}"
  content = hcloud_server.nova.ipv6_address
  type    = "AAAA"
  ttl     = 300

  comment = "Nova server IPv6 address - managed by Terraform"
}

resource "cloudflare_dns_record" "psuite_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = "psuite.hetzner.${var.dns_domain}"
  content = hcloud_server.nova.ipv6_address
  type    = "AAAA"
  ttl     = 300

  comment = "PSuite server IPv6 address - managed by Terraform"
}

resource "cloudflare_dns_record" "wiki_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = "wiki.hetzner.${var.dns_domain}"
  content = hcloud_server.nova.ipv6_address
  type    = "AAAA"
  ttl     = 300

  comment = "Psuite Wiki hetzner IPv6 address - managed by Terraform"
}

resource "cloudflare_dns_record" "fava_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = "fava.hetzner.${var.dns_domain}"
  content = hcloud_server.nova.ipv6_address
  type    = "AAAA"
  ttl     = 300

  comment = "Psuite Fava hetzner IPv6 address - managed by Terraform"
}
