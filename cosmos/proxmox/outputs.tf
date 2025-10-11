output "fireland_bucket_id" {
  value = module.fireland_s3.bucket_id
}

output "valkyrie_bucket_access_key" {
  value = module.valkyrie_s3.access_key
}

output "valkyrie_bucket_secret_key" {
  value     = module.valkyrie_s3.secret_key
  sensitive = true
}

output "fireland_bucket_access_key" {
  value = module.fireland_s3.access_key
}

output "fireland_bucket_secret_key" {
  value     = module.fireland_s3.secret_key
  sensitive = true
}

output "odin_bucket_access_key" {
  value = module.odin_s3.access_key
}

output "odin_bucket_secret_key" {
  value     = module.odin_s3.secret_key
  sensitive = true
}

output "chillyfries_bucket_access_key" {
  value = module.chillyfries_s3.access_key
}

output "chillyfries_bucket_secret_key" {
  value     = module.chillyfries_s3.secret_key
  sensitive = true
}

output "valheim_rivers_ip" {
  value       = proxmox_virtual_environment_vm.valheim_rivers.ipv4_addresses[1][0]
  description = "IP address of the Valheim Rivers server"
}
