output "fireland_bucket_id" {
  value = module.fireland_s3.bucket_id
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
