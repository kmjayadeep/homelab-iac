variable "ssh_public_key_name" {
  description = "Name of the SSH public key in Hetzner Cloud"
  type        = string
  default     = "main"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for DNS records"
  type        = string
}

variable "dns_domain" {
  description = "Domain name for DNS records"
  type        = string
  default     = "cboxlab.com"
}
