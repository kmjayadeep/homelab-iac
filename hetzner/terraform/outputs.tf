output "nova_ipv6_address" {
  description = "The public IPv6 address of the server"
  value       = hcloud_server.nova.ipv6_address
}

output "nova_dns_fqdn" {
  description = "The fully qualified domain name for the nova server"
  value       = cloudflare_dns_record.nova_aaaa.name
}

output "nova_ssh_connection_command_ipv6" {
  description = "SSH command to connect to the server via IPv6"
  value       = "ssh -6 root@${hcloud_server.nova.ipv6_address}"
}

output "nova_ssh_connection_command_dns" {
  description = "SSH command to connect to the server via DNS"
  value       = "ssh root@${cloudflare_dns_record.nova_aaaa.name}"
}
