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
