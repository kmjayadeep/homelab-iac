output "nova_ipv6_address" {
  description = "The public IPv6 address of the server"
  value       = hcloud_server.nova.ipv6_address
}

output "nova_ssh_connection_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.nova.ipv6_address}"
}
