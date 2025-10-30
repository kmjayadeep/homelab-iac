variable "cloudinit_username" {
  default = "cosmos"
}
variable "cloudinit_password" {
  default = "cosmos"
}
variable "cloudinit_ssh_public_key" {
}

variable "cloudflare_zone_id" {
  description = "CloudFlare Zone ID for DNS records"
  type        = string
}

variable "cloudflare_domain" {
  description = "Domain name for DNS records"
  type        = string
  default     = "cboxlab.com"
}

variable "cloudflare_api_token" {
  description = "API Token for Cloudflare provider"
  type        = string
}

variable "acme_email" {
  description = "Email address for ACME"
  type        = string
}
