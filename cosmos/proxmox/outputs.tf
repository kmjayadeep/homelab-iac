output "fireland_bucket_id" {
  value = module.fireland_s3.bucket_id
}

output "valkyrie_bucket_access_key" {
  value     = module.valkyrie_s3.access_key
  sensitive = true
}

output "valkyrie_bucket_secret_key" {
  value     = module.valkyrie_s3.secret_key
  sensitive = true
}

output "fireland_bucket_access_key" {
  value     = module.fireland_s3.access_key
  sensitive = true
}

output "fireland_bucket_secret_key" {
  value     = module.fireland_s3.secret_key
  sensitive = true
}

output "odin_bucket_access_key" {
  value     = module.odin_s3.access_key
  sensitive = true
}

output "odin_bucket_secret_key" {
  value     = module.odin_s3.secret_key
  sensitive = true
}

output "chillyfries_bucket_access_key" {
  value     = module.chillyfries_s3.access_key
  sensitive = true
}

output "chillyfries_bucket_secret_key" {
  value     = module.chillyfries_s3.secret_key
  sensitive = true
}

output "valheim_rivers_ip" {
  value       = try(proxmox_virtual_environment_vm.valheim_rivers.ipv4_addresses[1][0], "192.168.1.98")
  description = "IP address of the Valheim Rivers server"
}

output "windrose_ip" {
  value       = proxmox_virtual_environment_vm.windrose.ipv4_addresses[1][0]
  description = "IP address of the Windrose dedicated server"
}

output "windrose_bucket_access_key" {
  value     = module.windrose_s3.access_key
  sensitive = true
}

output "windrose_bucket_secret_key" {
  value     = module.windrose_s3.secret_key
  sensitive = true
}

output "valheim_rivers_bucket_access_key" {
  value     = module.valheim_rivers_s3.access_key
  sensitive = true
}

output "valheim_rivers_bucket_secret_key" {
  value     = module.valheim_rivers_s3.secret_key
  sensitive = true
}

output "openclaw_bucket_access_key" {
  value     = module.openclaw_s3.access_key
  sensitive = true
}

output "openclaw_bucket_secret_key" {
  value     = module.openclaw_s3.secret_key
  sensitive = true
}
