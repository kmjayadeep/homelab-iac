resource "minio_iam_user" "monitoring" {
  name = "monitoring"
}

resource "minio_iam_policy" "monitoring-policy" {
  name = "monitoring-policy"
  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Effect = "Allow"
      Resource = [
        "${minio_s3_bucket.nuc-backup.arn}",
        "${minio_s3_bucket.nuc-backup.arn}/*",
        "${minio_s3_bucket.nuc-private-backup.arn}",
        "${minio_s3_bucket.nuc-private-backup.arn}/*",
        "${minio_s3_bucket.thanos-cosmos.arn}",
        "${minio_s3_bucket.thanos-cosmos.arn}/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "monitoring" {
  user_name   = minio_iam_user.monitoring.id
  policy_name = minio_iam_policy.monitoring-policy.id
}

resource "minio_iam_service_account" "monitoring-restic" {
  target_user = minio_iam_user.monitoring.name
  policy      = minio_iam_policy.monitoring-policy.policy
}

output "monitoring_access_key" {
  value     = minio_iam_service_account.monitoring-restic.access_key
  sensitive = true
}

output "monitoring_secret_key" {
  value     = minio_iam_service_account.monitoring-restic.secret_key
  sensitive = true
}
