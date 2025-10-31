# DNS Record for nova server IPv6
resource "cloudflare_dns_record" "nova_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = "nova.hetzner"
  content = hcloud_server.nova.ipv6_address
  type    = "AAAA"
  ttl     = 300
  
  comment = "Nova server IPv6 address - managed by Terraform"
}
