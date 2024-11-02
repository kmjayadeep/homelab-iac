output "bucket_id" {
  value = minio_s3_bucket.this.id
}

output "bucket_arn" {
  value = minio_s3_bucket.this.arn
}

output "access_key" {
  value = length(minio_iam_service_account.this) == 1 ? minio_iam_service_account.this[0].access_key : ""
}

output "secret_key" {
  value     = length(minio_iam_service_account.this) == 1 ? minio_iam_service_account.this[0].secret_key : ""
  sensitive = true
}
